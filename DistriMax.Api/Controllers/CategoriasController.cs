using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using DistriMax.Api.Data;
using DistriMax.Api.Helpers;
using DistriMax.Common.DTOs;

namespace DistriMax.Api.Controllers
{
    [RoutePrefix("api/categorias")]
    public class CategoriasController : ApiController
    {
        [HttpGet]
        [Route("")]
        public IHttpActionResult Listar()
        {
            if (TokenHelper.ValidarToken(Request) == 0) return Unauthorized();

            DistriMaxEntities db = new DistriMaxEntities();
            List<Categoria> todas = db.Categorias.ToList();

            List<CategoriaDTO> lista = todas.Select(c => new CategoriaDTO
            {
                IdCategoria = c.IdCategoria,
                Nombre = c.Nombre,
                IdCategoriaPadre = c.IdCategoriaPadre,
                CategoriaPadre = c.IdCategoriaPadre.HasValue
                    ? todas.Where(x => x.IdCategoria == c.IdCategoriaPadre.Value).Select(x => x.Nombre).FirstOrDefault()
                    : null,
                Activa = c.Activa
            }).OrderBy(x => x.CategoriaPadre ?? x.Nombre).ThenBy(x => x.Nombre).ToList();

            return Ok(lista);
        }

        [HttpPost]
        [Route("")]
        public IHttpActionResult Guardar(CategoriaDTO dto)
        {
            int idUsuario = TokenHelper.ValidarToken(Request);
            if (idUsuario == 0) return Unauthorized();

            if (dto == null || string.IsNullOrEmpty(dto.Nombre))
                return Ok(new RespuestaDTO { ok = false, mensaje = "El nombre es obligatorio" });

            DistriMaxEntities db = new DistriMaxEntities();
            Categoria c;
            if (dto.IdCategoria == 0)
            {
                c = new Categoria();
                db.Categorias.Add(c);
            }
            else
            {
                c = db.Categorias.Find(dto.IdCategoria);
                if (c == null) return NotFound();
            }
            c.Nombre = dto.Nombre.Trim();
            c.IdCategoriaPadre = dto.IdCategoriaPadre;
            c.Activa = dto.Activa;
            db.SaveChanges();

            LogHelper.Log(idUsuario, "Categorias", dto.IdCategoria == 0 ? "Crear" : "Editar", c.Nombre);
            return Ok(new RespuestaDTO { ok = true, mensaje = "Categoría guardada", data = c.IdCategoria });
        }
    }
}
