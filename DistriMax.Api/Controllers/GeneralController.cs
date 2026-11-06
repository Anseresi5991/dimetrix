using System;
using System.Data;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using DistriMax.Api.Data;

namespace DistriMax.Api.Controllers
{
    [RoutePrefix("api/general")]
    public class GeneralController : ApiController
    {
        [HttpGet]
        [Route("ping")]
        public HttpResponseMessage Ping()
        {
            object version = DbHelper.EjecutarEscalar("SELECT @@VERSION");
            return Request.CreateResponse(HttpStatusCode.OK, new { estado = "OK", servidor = Environment.MachineName, fecha = DateTime.Now, sql = version });
        }

        [HttpGet]
        [Route("departamentos")]
        public HttpResponseMessage Departamentos()
        {
            DataTable dt = DbHelper.EjecutarConsulta("SELECT IdDepartamento, Codigo, Nombre FROM Departamentos ORDER BY Nombre");
            return Request.CreateResponse(HttpStatusCode.OK, dt);
        }

        [HttpGet]
        [Route("ciudades")]
        public HttpResponseMessage Ciudades(string dpto = null)
        {
            string sql = "SELECT IdCiudad, IdDepartamento, Codigo, Nombre FROM Ciudades";
            if (!string.IsNullOrEmpty(dpto)) sql += " WHERE IdDepartamento = " + dpto;
            sql += " ORDER BY Nombre";
            DataTable dt = DbHelper.EjecutarConsulta(sql);
            return Request.CreateResponse(HttpStatusCode.OK, dt);
        }

        [HttpGet]
        [Route("bodegas")]
        public HttpResponseMessage Bodegas()
        {
            DataTable dt = DbHelper.EjecutarConsulta("SELECT IdBodega, Nombre, Direccion, Activa FROM Bodegas WHERE Activa = 1 ORDER BY IdBodega");
            return Request.CreateResponse(HttpStatusCode.OK, dt);
        }

        [HttpGet]
        [Route("listasprecios")]
        public HttpResponseMessage ListasPrecios()
        {
            DataTable dt = DbHelper.EjecutarConsulta("SELECT IdLista, Nombre, Activa FROM ListasPrecios WHERE Activa = 1 ORDER BY Nombre");
            return Request.CreateResponse(HttpStatusCode.OK, dt);
        }

        [HttpGet]
        [Route("roles")]
        public HttpResponseMessage Roles()
        {
            DataTable dt = DbHelper.EjecutarConsulta("SELECT IdRol, Nombre FROM Roles WHERE Activo = 1 ORDER BY IdRol");
            return Request.CreateResponse(HttpStatusCode.OK, dt);
        }
    }
}
