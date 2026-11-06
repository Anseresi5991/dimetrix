using System;
using System.Configuration;
using System.Net.Http;
using System.Text;
using System.Web;
using DistriMax.Common.DTOs;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace DistriMax.Web.Helpers
{
    public class ApiHelper
    {
        public static string UrlApi = ConfigurationManager.AppSettings["UrlApi"];

        // AP-03: un HttpClient nuevo por cada llamada (agota sockets bajo carga)
        private static HttpClient CrearCliente()
        {
            HttpClient client = new HttpClient();
            client.BaseAddress = new Uri(UrlApi);
            client.DefaultRequestHeaders.Add("X-Api-Key", ConfigurationManager.AppSettings["ApiKey"]);
            if (HttpContext.Current != null && HttpContext.Current.Session != null && HttpContext.Current.Session["Token"] != null)
            {
                client.DefaultRequestHeaders.Add("X-Token", HttpContext.Current.Session["Token"].ToString());
            }
            return client;
        }

        // AP-16: sync over async con .Result
        // BUG-03: si el token expiró, esto lanza una excepción genérica en vez de mandar al login
        public static T Get<T>(string url)
        {
            HttpClient client = CrearCliente();
            HttpResponseMessage resp = client.GetAsync(url).Result;
            string json = resp.Content.ReadAsStringAsync().Result;
            if (!resp.IsSuccessStatusCode)
            {
                throw new Exception("Error API (" + (int)resp.StatusCode + "): " + ExtraerMensaje(json));
            }
            return JsonConvert.DeserializeObject<T>(json);
        }

        public static RespuestaDTO Post(string url, object datos)
        {
            return Enviar("POST", url, datos);
        }

        public static RespuestaDTO Put(string url, object datos)
        {
            return Enviar("PUT", url, datos);
        }

        private static RespuestaDTO Enviar(string metodo, string url, object datos)
        {
            HttpClient client = CrearCliente();
            string json = datos == null ? "{}" : JsonConvert.SerializeObject(datos);
            StringContent contenido = new StringContent(json, Encoding.UTF8, "application/json");

            HttpResponseMessage resp;
            if (metodo == "PUT")
                resp = client.PutAsync(url, contenido).Result;
            else
                resp = client.PostAsync(url, contenido).Result;

            string respuesta = resp.Content.ReadAsStringAsync().Result;

            RespuestaDTO r = null;
            try
            {
                r = JsonConvert.DeserializeObject<RespuestaDTO>(respuesta);
            }
            catch
            {
                // AP-18: si no es RespuestaDTO, se arma una a mano
            }

            if (r == null)
            {
                r = new RespuestaDTO();
                r.ok = resp.IsSuccessStatusCode;
            }
            if (string.IsNullOrEmpty(r.mensaje))
            {
                r.mensaje = resp.IsSuccessStatusCode ? "OK" : ExtraerMensaje(respuesta);
            }
            if (!resp.IsSuccessStatusCode)
            {
                r.ok = false;
            }
            return r;
        }

        public static T ConvertirData<T>(object data)
        {
            if (data == null) return default(T);
            return JToken.FromObject(data).ToObject<T>();
        }

        public static string ExtraerMensaje(string json)
        {
            try
            {
                JToken t = JToken.Parse(json);
                if (t.Type == JTokenType.String) return t.ToString();
                if (t.Type == JTokenType.Object)
                {
                    if (t["mensaje"] != null) return t["mensaje"].ToString();
                    if (t["Message"] != null) return t["Message"].ToString();
                }
            }
            catch
            {
            }
            return json;
        }
    }
}
