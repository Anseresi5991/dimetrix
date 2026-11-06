using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using DistriMax.Api.Data;
using DistriMax.Api.Helpers;
using DistriMax.Common.DTOs;

namespace DistriMax.Api.Controllers
{
    [RoutePrefix("api/clientes")]
    public class ClientesController : ApiController
    {
        [HttpGet]
        [Route("")]
        public HttpResponseMessage Listar(string buscar = null)
        {
            // AP-04: validación de token copiada y pegada en cada action
            IEnumerable<string> tokens;
            if (!Request.Headers.TryGetValues("X-Token", out tokens))
                return Request.CreateResponse(HttpStatusCode.Unauthorized, "Token requerido");
            DataTable dtTok = DbHelper.EjecutarConsulta("SELECT IdUsuario FROM Usuarios WHERE Token = '" + tokens.First() + "' AND TokenExpira > GETDATE()");
            if (dtTok.Rows.Count == 0)
                return Request.CreateResponse(HttpStatusCode.Unauthorized, "Token inválido o expirado");

            try
            {
                DataTable dt = DbHelper.EjecutarSP("sp_Clientes_Listar",
                    new SqlParameter("@Buscar", string.IsNullOrEmpty(buscar) ? (object)DBNull.Value : buscar));
                return Request.CreateResponse(HttpStatusCode.OK, dt); // AP-11: devuelve el DataTable crudo
            }
            catch (Exception ex)
            {
                LogHelper.Error(ex, Request.RequestUri.ToString());
                return Request.CreateResponse(HttpStatusCode.InternalServerError, ex.Message);
            }
        }

        [HttpGet]
        [Route("{id:int}")]
        public HttpResponseMessage Obtener(int id)
        {
            // AP-04: misma validación, copiada
            IEnumerable<string> tokens;
            if (!Request.Headers.TryGetValues("X-Token", out tokens))
                return Request.CreateResponse(HttpStatusCode.Unauthorized, "Token requerido");
            DataTable dtTok = DbHelper.EjecutarConsulta("SELECT IdUsuario FROM Usuarios WHERE Token = '" + tokens.First() + "' AND TokenExpira > GETDATE()");
            if (dtTok.Rows.Count == 0)
                return Request.CreateResponse(HttpStatusCode.Unauthorized, "Token inválido o expirado");

            try
            {
                DataTable dt = DbHelper.EjecutarSP("sp_Clientes_Obtener", new SqlParameter("@IdCliente", id));
                if (dt.Rows.Count == 0)
                    return Request.CreateResponse(HttpStatusCode.NotFound, "Cliente no encontrado");

                // AP-27: mapeo manual del DataRow
                DataRow r = dt.Rows[0];
                ClienteDTO c = new ClienteDTO();
                c.IdCliente = Convert.ToInt32(r["IdCliente"]);
                c.TipoDocumento = r["TipoDocumento"].ToString();
                c.NumeroDocumento = r["NumeroDocumento"].ToString();
                c.DV = r["DV"] == DBNull.Value ? null : r["DV"].ToString();
                c.RazonSocial = r["RazonSocial"].ToString();
                c.NombreComercial = r["NombreComercial"] == DBNull.Value ? null : r["NombreComercial"].ToString();
                c.Direccion = r["Direccion"] == DBNull.Value ? null : r["Direccion"].ToString();
                c.IdCiudad = r["IdCiudad"] == DBNull.Value ? (int?)null : Convert.ToInt32(r["IdCiudad"]);
                c.Ciudad = r["Ciudad"] == DBNull.Value ? null : r["Ciudad"].ToString();
                c.IdDepartamento = r["IdDepartamento"] == DBNull.Value ? (int?)null : Convert.ToInt32(r["IdDepartamento"]);
                c.Departamento = r["Departamento"] == DBNull.Value ? null : r["Departamento"].ToString();
                c.Telefono = r["Telefono"] == DBNull.Value ? null : r["Telefono"].ToString();
                c.Email = r["Email"] == DBNull.Value ? null : r["Email"].ToString();
                c.CupoCredito = Convert.ToDecimal(r["CupoCredito"]);
                c.DiasCredito = Convert.ToInt32(r["DiasCredito"]);
                c.IdLista = r["IdLista"] == DBNull.Value ? (int?)null : Convert.ToInt32(r["IdLista"]);
                c.ListaPrecios = r["ListaPrecios"] == DBNull.Value ? null : r["ListaPrecios"].ToString();
                c.IdVendedor = r["IdVendedor"] == DBNull.Value ? (int?)null : Convert.ToInt32(r["IdVendedor"]);
                c.Vendedor = r["Vendedor"] == DBNull.Value ? null : r["Vendedor"].ToString();
                c.Bloqueado = Convert.ToBoolean(r["Bloqueado"]);
                c.MotivoBloqueo = r["MotivoBloqueo"] == DBNull.Value ? null : r["MotivoBloqueo"].ToString();
                c.Activo = Convert.ToBoolean(r["Activo"]);
                c.FechaCreacion = Convert.ToDateTime(r["FechaCreacion"]);
                c.Saldo = Convert.ToDecimal(r["Saldo"]);

                return Request.CreateResponse(HttpStatusCode.OK, c);
            }
            catch (Exception ex)
            {
                LogHelper.Error(ex, Request.RequestUri.ToString());
                return Request.CreateResponse(HttpStatusCode.InternalServerError, ex.Message);
            }
        }

        [HttpPost]
        [Route("")]
        public HttpResponseMessage Guardar(ClienteDTO c)
        {
            // AP-04: otra vez
            IEnumerable<string> tokens;
            if (!Request.Headers.TryGetValues("X-Token", out tokens))
                return Request.CreateResponse(HttpStatusCode.Unauthorized, "Token requerido");
            DataTable dtTok = DbHelper.EjecutarConsulta("SELECT IdUsuario FROM Usuarios WHERE Token = '" + tokens.First() + "' AND TokenExpira > GETDATE()");
            if (dtTok.Rows.Count == 0)
                return Request.CreateResponse(HttpStatusCode.Unauthorized, "Token inválido o expirado");
            int idUsuario = Convert.ToInt32(dtTok.Rows[0]["IdUsuario"]);

            try
            {
                if (c == null)
                    return Request.CreateResponse(HttpStatusCode.BadRequest, new RespuestaDTO { ok = false, mensaje = "Datos vacíos" });

                // AP-01: validaciones de negocio dentro del controller
                string errores = "";
                if (string.IsNullOrEmpty(c.RazonSocial)) errores += "La razón social es obligatoria. ";
                if (!ApiUtils.SoloNumeros(c.NumeroDocumento)) errores += "El número de documento es obligatorio y solo admite números. ";
                if (c.TipoDocumento != "NIT" && c.TipoDocumento != "CC") errores += "Tipo de documento inválido. ";
                // AP-05: validación de email distinta a la del front (aquí solo se mira la @)
                if (!string.IsNullOrEmpty(c.Email) && !c.Email.Contains("@")) errores += "El email no es válido. ";
                if (c.CupoCredito < 0) errores += "El cupo no puede ser negativo. ";
                if (c.DiasCredito < 0 || c.DiasCredito > 120) errores += "Los días de crédito deben estar entre 0 y 120. ";

                if (errores != "")
                    return Request.CreateResponse(HttpStatusCode.BadRequest, new RespuestaDTO { ok = false, mensaje = errores.Trim() });

                // Regla "escondida": cliente de contado no tiene cupo
                if (c.DiasCredito == 0) c.CupoCredito = 0;

                // El DV se recalcula aquí aunque el front ya lo mande calculado
                if (c.TipoDocumento == "NIT") c.DV = ApiUtils.DigitoVerificacion(c.NumeroDocumento);
                else c.DV = null;

                if (!c.Bloqueado) c.MotivoBloqueo = null;

                DataTable dt = DbHelper.EjecutarSP("sp_Clientes_Guardar",
                    new SqlParameter("@IdCliente", c.IdCliente),
                    new SqlParameter("@TipoDocumento", c.TipoDocumento),
                    new SqlParameter("@NumeroDocumento", c.NumeroDocumento),
                    ApiUtils.Param("@DV", c.DV),
                    new SqlParameter("@RazonSocial", c.RazonSocial.Trim()),
                    ApiUtils.Param("@NombreComercial", c.NombreComercial),
                    ApiUtils.Param("@Direccion", c.Direccion),
                    ApiUtils.Param("@IdCiudad", c.IdCiudad),
                    ApiUtils.Param("@Telefono", c.Telefono),
                    ApiUtils.Param("@Email", c.Email),
                    new SqlParameter("@CupoCredito", c.CupoCredito),
                    new SqlParameter("@DiasCredito", c.DiasCredito),
                    ApiUtils.Param("@IdLista", c.IdLista),
                    ApiUtils.Param("@IdVendedor", c.IdVendedor),
                    new SqlParameter("@Bloqueado", c.Bloqueado),
                    ApiUtils.Param("@MotivoBloqueo", c.MotivoBloqueo),
                    new SqlParameter("@Activo", c.Activo));

                int id = Convert.ToInt32(dt.Rows[0]["IdCliente"]);
                LogHelper.Log(idUsuario, "Clientes", c.IdCliente == 0 ? "Crear" : "Editar",
                    "{\"IdCliente\":" + id + ",\"Documento\":\"" + c.NumeroDocumento + "\",\"Cupo\":" + c.CupoCredito + "}");

                return Request.CreateResponse(HttpStatusCode.OK, new RespuestaDTO { ok = true, mensaje = "Cliente guardado", data = id });
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

        [HttpGet]
        [Route("{id:int}/saldo")]
        public HttpResponseMessage Saldo(int id)
        {
            // Este se le "olvidó" validar el token a alguien (AP-04)
            try
            {
                DataTable dt = DbHelper.EjecutarSP("sp_Clientes_SaldoCartera", new SqlParameter("@IdCliente", id));
                return Request.CreateResponse(HttpStatusCode.OK, dt);
            }
            catch (Exception ex)
            {
                return Request.CreateResponse(HttpStatusCode.InternalServerError, ex.Message);
            }
        }
    }
}
