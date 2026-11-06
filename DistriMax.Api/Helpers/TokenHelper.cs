using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Net.Http;
using DistriMax.Api.Data;

namespace DistriMax.Api.Helpers
{
    public class TokenHelper
    {
        // Devuelve el IdUsuario dueño del token o 0 si no es válido
        public static int ValidarToken(HttpRequestMessage request)
        {
            try
            {
                IEnumerable<string> valores;
                if (!request.Headers.TryGetValues("X-Token", out valores)) return 0;
                string token = valores.FirstOrDefault();
                if (string.IsNullOrEmpty(token)) return 0;

                DataTable dt = DbHelper.EjecutarConsulta("SELECT IdUsuario FROM Usuarios WHERE Token = '" + token + "' AND TokenExpira > GETDATE() AND Activo = 1");
                if (dt.Rows.Count == 0) return 0;
                return Convert.ToInt32(dt.Rows[0]["IdUsuario"]);
            }
            catch
            {
                return 0;
            }
        }

        public static bool ValidarApiKey(HttpRequestMessage request)
        {
            IEnumerable<string> valores;
            if (!request.Headers.TryGetValues("X-Api-Key", out valores)) return false;
            return valores.FirstOrDefault() == ConfigurationManager.AppSettings["ApiKey"];
        }
    }
}
