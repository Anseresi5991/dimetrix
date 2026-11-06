using System;
using System.Data;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using DistriMax.Api.Data;
using DistriMax.Api.Helpers;
using DistriMax.Common;
using DistriMax.Common.DTOs;

namespace DistriMax.Api.Controllers
{
    // Proveedores: todo con SQL concatenado (AP-13). Ningún SP.
    [RoutePrefix("api/proveedores")]
    public class ProveedoresController : ApiController
    {
        private const string SELECT_BASE = "SELECT p.Proveedor_Id, p.Nit, p.DV, p.RazonSocial, p.Contacto, p.Telefono, p.Email, p.IdCiudad, "
            + "c.Nombre AS Ciudad, c.IdDepartamento, p.DiasPago, p.Activo FROM Proveedor p LEFT JOIN Ciudades c ON c.IdCiudad = p.IdCiudad";

        [HttpGet]
        [Route("")]
        public HttpResponseMessage Listar(string buscar = null)
        {
            if (TokenHelper.ValidarToken(Request) == 0)
                return Request.CreateResponse(HttpStatusCode.Unauthorized, new RespuestaDTO { ok = false, mensaje = "Token inválido o expirado" });

            try
            {
                string sql = SELECT_BASE;
                if (!string.IsNullOrEmpty(buscar))
                {
                    // AP-13: SQL injection de libro
                    sql += " WHERE p.RazonSocial LIKE '%" + buscar + "%' OR p.Nit LIKE '%" + buscar + "%'";
                }
                sql += " ORDER BY p.RazonSocial";

                DataTable dt = DbHelper.EjecutarConsulta(sql);
                return Request.CreateResponse(HttpStatusCode.OK, new RespuestaDTO { ok = true, mensaje = "OK", data = dt });
            }
            catch (Exception ex)
            {
                LogHelper.Error(ex, Request.RequestUri.ToString());
                return Request.CreateResponse(HttpStatusCode.InternalServerError, new RespuestaDTO { ok = false, mensaje = ex.Message });
            }
        }

        // AP-11: devuelve una LISTA con un solo elemento dentro de RespuestaDTO
        [HttpGet]
        [Route("{id:int}")]
        public HttpResponseMessage Obtener(int id)
        {
            if (TokenHelper.ValidarToken(Request) == 0)
                return Request.CreateResponse(HttpStatusCode.Unauthorized, new RespuestaDTO { ok = false, mensaje = "Token inválido o expirado" });

            DataTable dt = DbHelper.EjecutarConsulta(SELECT_BASE + " WHERE p.Proveedor_Id = " + id);
            return Request.CreateResponse(HttpStatusCode.OK, new RespuestaDTO { ok = dt.Rows.Count > 0, mensaje = dt.Rows.Count > 0 ? "OK" : "No encontrado", data = dt });
        }

        [HttpPost]
        [Route("")]
        public HttpResponseMessage Guardar(ProveedorDTO p)
        {
            int idUsuario = TokenHelper.ValidarToken(Request);
            if (idUsuario == 0)
                return Request.CreateResponse(HttpStatusCode.Unauthorized, new RespuestaDTO { ok = false, mensaje = "Token inválido o expirado" });

            try
            {
                if (p == null || string.IsNullOrEmpty(p.RazonSocial) || !ApiUtils.SoloNumeros(p.Nit))
                    return Request.CreateResponse(HttpStatusCode.BadRequest, new RespuestaDTO { ok = false, mensaje = "Razón social y NIT (numérico) son obligatorios" });

                if (!string.IsNullOrEmpty(p.Email) && !Utils.EsEmailValido(p.Email))
                    return Request.CreateResponse(HttpStatusCode.BadRequest, new RespuestaDTO { ok = false, mensaje = "El email no es válido" });

                p.DV = ApiUtils.DigitoVerificacion(p.Nit);
                string idCiudad = p.IdCiudad.HasValue ? p.IdCiudad.Value.ToString() : "NULL";
                string sql;

                // AP-13: solo la razón social escapa comillas; el resto se va "derecho"
                if (p.Proveedor_Id == 0)
                {
                    object existe = DbHelper.EjecutarEscalar("SELECT COUNT(*) FROM Proveedor WHERE Nit = '" + p.Nit + "'");
                    if (Convert.ToInt32(existe) > 0)
                        return Request.CreateResponse(HttpStatusCode.BadRequest, new RespuestaDTO { ok = false, mensaje = "Ya existe un proveedor con ese NIT" });

                    sql = "INSERT INTO Proveedor (Nit, DV, RazonSocial, Contacto, Telefono, Email, IdCiudad, DiasPago, Activo) VALUES ('"
                        + p.Nit + "', '" + p.DV + "', '" + p.RazonSocial.Replace("'", "''") + "', '" + p.Contacto + "', '"
                        + p.Telefono + "', '" + p.Email + "', " + idCiudad + ", " + p.DiasPago + ", " + (p.Activo ? "1" : "0")
                        + "); SELECT CAST(SCOPE_IDENTITY() AS INT);";
                    object nuevoId = DbHelper.EjecutarEscalar(sql);
                    p.Proveedor_Id = Convert.ToInt32(nuevoId);
                    LogHelper.Log(idUsuario, "Proveedores", "Crear", p.Nit + " " + p.RazonSocial);
                }
                else
                {
                    sql = "UPDATE Proveedor SET Nit = '" + p.Nit + "', DV = '" + p.DV + "', RazonSocial = '" + p.RazonSocial.Replace("'", "''")
                        + "', Contacto = '" + p.Contacto + "', Telefono = '" + p.Telefono + "', Email = '" + p.Email
                        + "', IdCiudad = " + idCiudad + ", DiasPago = " + p.DiasPago + ", Activo = " + (p.Activo ? "1" : "0")
                        + " WHERE Proveedor_Id = " + p.Proveedor_Id;
                    DbHelper.EjecutarComando(sql);
                    LogHelper.Log(idUsuario, "Proveedores", "Editar", p.Nit + " " + p.RazonSocial);
                }

                return Request.CreateResponse(HttpStatusCode.OK, new RespuestaDTO { ok = true, mensaje = "Proveedor guardado", data = p.Proveedor_Id });
            }
            catch (Exception ex)
            {
                LogHelper.Error(ex, Request.RequestUri.ToString());
                return Request.CreateResponse(HttpStatusCode.InternalServerError, new RespuestaDTO { ok = false, mensaje = ex.Message });
            }
        }
    }
}
