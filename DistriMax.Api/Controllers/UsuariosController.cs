using System;
using System.Data;
using System.Data.SqlClient;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using DistriMax.Api.Data;
using DistriMax.Api.Helpers;
using DistriMax.Common;
using DistriMax.Common.DTOs;

namespace DistriMax.Api.Controllers
{
    [RoutePrefix("api/usuarios")]
    public class UsuariosController : ApiController
    {
        [HttpGet]
        [Route("")]
        public HttpResponseMessage Listar()
        {
            int idUsuario = TokenHelper.ValidarToken(Request);
            if (idUsuario == 0)
                return Request.CreateResponse(HttpStatusCode.Unauthorized, new RespuestaDTO { ok = false, mensaje = "Token inválido o expirado" });

            try
            {
                DataTable dt = DbHelper.EjecutarSP("sp_Usuarios_Listar");
                return Request.CreateResponse(HttpStatusCode.OK, dt);
            }
            catch (Exception ex)
            {
                LogHelper.Error(ex, Request.RequestUri.ToString());
                return Request.CreateResponse(HttpStatusCode.InternalServerError, new RespuestaDTO { ok = false, mensaje = ex.Message });
            }
        }

        [HttpGet]
        [Route("{id:int}")]
        public HttpResponseMessage Obtener(int id)
        {
            int idUsuario = TokenHelper.ValidarToken(Request);
            if (idUsuario == 0)
                return Request.CreateResponse(HttpStatusCode.Unauthorized, new RespuestaDTO { ok = false, mensaje = "Token inválido o expirado" });

            DataTable dt = DbHelper.EjecutarConsulta("SELECT u.IdUsuario, u.Login, u.Nombre, u.Email, u.IdRol, r.Nombre AS Rol, u.Activo, u.UltimoAcceso, u.FechaCreacion "
                + "FROM Usuarios u INNER JOIN Roles r ON r.IdRol = u.IdRol WHERE u.IdUsuario = " + id);

            if (dt.Rows.Count == 0)
                return Request.CreateResponse(HttpStatusCode.NotFound, new RespuestaDTO { ok = false, mensaje = "Usuario no encontrado" });

            DataRow r = dt.Rows[0];
            UsuarioDTO u = new UsuarioDTO();
            u.IdUsuario = Utils.ToInt(r["IdUsuario"]);
            u.Login = Utils.ToStr(r["Login"]);
            u.Nombre = Utils.ToStr(r["Nombre"]);
            u.Email = Utils.ToStr(r["Email"]);
            u.IdRol = Utils.ToInt(r["IdRol"]);
            u.Rol = Utils.ToStr(r["Rol"]);
            u.Activo = Utils.ToBool(r["Activo"]);
            u.UltimoAcceso = Utils.ToFecha(r["UltimoAcceso"]);
            u.FechaCreacion = Utils.ToFecha(r["FechaCreacion"]);
            return Request.CreateResponse(HttpStatusCode.OK, u);
        }

        [HttpGet]
        [Route("vendedores")]
        public HttpResponseMessage Vendedores()
        {
            int idUsuario = TokenHelper.ValidarToken(Request);
            if (idUsuario == 0)
                return Request.CreateResponse(HttpStatusCode.Unauthorized, new RespuestaDTO { ok = false, mensaje = "Token inválido o expirado" });

            DataTable dt = DbHelper.EjecutarConsulta("SELECT IdUsuario, Nombre FROM Usuarios WHERE IdRol = 3 AND Activo = 1 ORDER BY Nombre");
            return Request.CreateResponse(HttpStatusCode.OK, dt);
        }

        [HttpPost]
        [Route("")]
        public HttpResponseMessage Guardar(UsuarioDTO u)
        {
            int idUsuario = TokenHelper.ValidarToken(Request);
            if (idUsuario == 0)
                return Request.CreateResponse(HttpStatusCode.Unauthorized, new RespuestaDTO { ok = false, mensaje = "Token inválido o expirado" });

            try
            {
                if (u == null)
                    return Request.CreateResponse(HttpStatusCode.BadRequest, new RespuestaDTO { ok = false, mensaje = "Datos vacíos" });

                string errores = "";
                if (string.IsNullOrEmpty(u.Login)) errores += "El login es obligatorio. ";
                if (string.IsNullOrEmpty(u.Nombre)) errores += "El nombre es obligatorio. ";
                if (u.IdRol <= 0) errores += "Debe seleccionar un rol. ";
                if (!string.IsNullOrEmpty(u.Email) && !Utils.EsEmailValido(u.Email)) errores += "El email no es válido. ";
                if (u.IdUsuario == 0 && string.IsNullOrEmpty(u.Password)) errores += "La contraseña es obligatoria. ";
                if (!string.IsNullOrEmpty(u.Password) && u.Password.Length < 6) errores += "La contraseña debe tener mínimo 6 caracteres. ";

                if (errores != "")
                    return Request.CreateResponse(HttpStatusCode.BadRequest, new RespuestaDTO { ok = false, mensaje = errores.Trim() });

                string hash = string.IsNullOrEmpty(u.Password) ? null : Utils.Md5(u.Password);

                DataTable dt = DbHelper.EjecutarSP("sp_Usuarios_Guardar",
                    new SqlParameter("@IdUsuario", u.IdUsuario),
                    new SqlParameter("@Login", u.Login.Trim().ToLower()),
                    new SqlParameter("@Password", (object)hash ?? DBNull.Value),
                    new SqlParameter("@Nombre", u.Nombre),
                    new SqlParameter("@Email", (object)u.Email ?? DBNull.Value),
                    new SqlParameter("@IdRol", u.IdRol),
                    new SqlParameter("@Activo", u.Activo));

                LogHelper.Log(idUsuario, "Usuarios", u.IdUsuario == 0 ? "Crear" : "Editar", u.Login);

                return Request.CreateResponse(HttpStatusCode.OK, new RespuestaDTO { ok = true, mensaje = "Usuario guardado", data = dt.Rows[0]["IdUsuario"] });
            }
            catch (SqlException ex)
            {
                return Request.CreateResponse(HttpStatusCode.BadRequest, new RespuestaDTO { ok = false, mensaje = ex.Message });
            }
            catch (Exception ex)
            {
                LogHelper.Error(ex, Request.RequestUri.ToString());
                return Request.CreateResponse(HttpStatusCode.InternalServerError, new RespuestaDTO { ok = false, mensaje = ex.Message });
            }
        }

        [HttpPut]
        [Route("{id:int}/password")]
        public HttpResponseMessage CambiarPassword(int id, CambioPasswordDTO datos)
        {
            int idUsuario = TokenHelper.ValidarToken(Request);
            if (idUsuario == 0)
                return Request.CreateResponse(HttpStatusCode.Unauthorized, new RespuestaDTO { ok = false, mensaje = "Token inválido o expirado" });

            if (datos == null || string.IsNullOrEmpty(datos.Password) || datos.Password.Length < 6)
                return Request.CreateResponse(HttpStatusCode.BadRequest, new RespuestaDTO { ok = false, mensaje = "La contraseña debe tener mínimo 6 caracteres" });

            DbHelper.EjecutarSP("sp_Usuarios_CambiarPassword",
                new SqlParameter("@IdUsuario", id),
                new SqlParameter("@Password", Utils.Md5(datos.Password)));

            LogHelper.Log(idUsuario, "Usuarios", "CambiarPassword", "IdUsuario=" + id);
            return Request.CreateResponse(HttpStatusCode.OK, new RespuestaDTO { ok = true, mensaje = "Contraseña actualizada" });
        }
    }
}
