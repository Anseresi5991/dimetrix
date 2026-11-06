using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using DistriMax.Api.Data;
using DistriMax.Api.Helpers;
using DistriMax.Common;
using DistriMax.Common.DTOs;

namespace DistriMax.Api.Controllers
{
    [RoutePrefix("api/auth")]
    public class AuthController : ApiController
    {
        [HttpPost]
        [Route("login")]
        public HttpResponseMessage Login(LoginDTO datos)
        {
            try
            {
                // El único endpoint que valida el ApiKey (los demás no, AP-04)
                if (!TokenHelper.ValidarApiKey(Request))
                {
                    return Request.CreateResponse(HttpStatusCode.Unauthorized, new RespuestaDTO { ok = false, mensaje = "ApiKey inválida" });
                }

                if (datos == null || string.IsNullOrEmpty(datos.Login) || string.IsNullOrEmpty(datos.Password))
                {
                    return Request.CreateResponse(HttpStatusCode.BadRequest, new RespuestaDTO { ok = false, mensaje = "Usuario y contraseña son obligatorios" });
                }

                string hash = Utils.Md5(datos.Password);
                DataTable dt = DbHelper.EjecutarSP("sp_Login",
                    new SqlParameter("@Login", datos.Login),
                    new SqlParameter("@Password", hash));

                if (dt.Rows.Count == 0)
                {
                    LogHelper.Log(0, "Seguridad", "LoginFallido", datos.Login);
                    return Request.CreateResponse(HttpStatusCode.Unauthorized, new RespuestaDTO { ok = false, mensaje = "Usuario o contraseña incorrectos" });
                }

                DataRow r = dt.Rows[0];
                string token = Guid.NewGuid().ToString();
                int horas = Convert.ToInt32(ConfigurationManager.AppSettings["TokenHorasExpiracion"]);

                // AP-13: UPDATE armado a mano
                DbHelper.EjecutarComando("UPDATE Usuarios SET Token = '" + token + "', TokenExpira = DATEADD(HOUR, " + horas
                    + ", GETDATE()), UltimoAcceso = GETDATE() WHERE IdUsuario = " + r["IdUsuario"]);

                UsuarioDTO usuario = new UsuarioDTO();
                usuario.IdUsuario = Convert.ToInt32(r["IdUsuario"]);
                usuario.Login = r["Login"].ToString();
                usuario.Nombre = r["Nombre"].ToString();
                usuario.Email = r["Email"] == DBNull.Value ? null : r["Email"].ToString();
                usuario.IdRol = Convert.ToInt32(r["IdRol"]);
                usuario.Rol = r["Rol"].ToString();
                usuario.Activo = true;
                usuario.Token = token;

                LogHelper.Log(usuario.IdUsuario, "Seguridad", "Login", "Ingreso exitoso desde " + Request.RequestUri.Host);

                return Request.CreateResponse(HttpStatusCode.OK, new RespuestaDTO { ok = true, mensaje = "OK", data = usuario });
            }
            catch (Exception ex)
            {
                LogHelper.Error(ex, Request.RequestUri.ToString());
                return Request.CreateResponse(HttpStatusCode.InternalServerError, new RespuestaDTO { ok = false, mensaje = ex.Message });
            }
        }

        [HttpPost]
        [Route("logout")]
        public HttpResponseMessage Logout()
        {
            IEnumerable<string> valores;
            if (Request.Headers.TryGetValues("X-Token", out valores))
            {
                DbHelper.EjecutarComando("UPDATE Usuarios SET Token = NULL, TokenExpira = NULL WHERE Token = '" + valores.First() + "'");
            }
            return Request.CreateResponse(HttpStatusCode.OK, new RespuestaDTO { ok = true, mensaje = "Sesión cerrada" });
        }
    }
}
