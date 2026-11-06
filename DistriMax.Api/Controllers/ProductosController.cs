using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using DistriMax.Api.Data;
using DistriMax.Api.Helpers;
using DistriMax.Common.DTOs;

namespace DistriMax.Api.Controllers
{
    // Productos usa EF6 (el "módulo moderno" que alguien empezó en 2018 y nunca terminó)
    [RoutePrefix("api/productos")]
    public class ProductosController : ApiController
    {
        [HttpGet]
        [Route("")]
        public IHttpActionResult Listar(string buscar = null, int? categoria = null)
        {
            if (TokenHelper.ValidarToken(Request) == 0) return Unauthorized();

            DistriMaxEntities db = new DistriMaxEntities(); // AP-28: nunca se hace Dispose

            var query = from p in db.Productos
                        join c in db.Categorias on p.IdCategoria equals c.IdCategoria
                        select new { p, c };

            if (!string.IsNullOrEmpty(buscar))
                query = query.Where(x => x.p.Nombre.Contains(buscar) || x.p.Codigo.Contains(buscar) || x.p.CodigoBarras == buscar);
            if (categoria.HasValue)
                query = query.Where(x => x.p.IdCategoria == categoria.Value || x.c.IdCategoriaPadre == categoria.Value);

            List<ProductoDTO> lista = query.OrderBy(x => x.p.Nombre).ToList().Select(x => new ProductoDTO
            {
                IdProducto = x.p.IdProducto,
                Codigo = x.p.Codigo,
                CodigoBarras = x.p.CodigoBarras,
                Nombre = x.p.Nombre,
                Descripcion = x.p.Descripcion,
                IdCategoria = x.p.IdCategoria,
                Categoria = x.c.Nombre,
                Unidad = x.p.Unidad,
                PorcIva = x.p.PorcIva,
                CostoPromedio = x.p.CostoPromedio,
                PrecioBase = x.p.PrecioBase,
                StockMinimo = x.p.StockMinimo,
                Activo = x.p.Activo
            }).ToList();

            // AP: N+1 consultas con ADO.NET dentro de un controller EF
            foreach (ProductoDTO p in lista)
            {
                object stock = DbHelper.EjecutarEscalar("SELECT ISNULL(SUM(Cantidad), 0) FROM Inventario WHERE IdProducto = " + p.IdProducto);
                p.StockTotal = Convert.ToDecimal(stock);
            }

            return Ok(lista);
        }

        [HttpGet]
        [Route("{id:int}")]
        public IHttpActionResult Obtener(int id)
        {
            if (TokenHelper.ValidarToken(Request) == 0) return Unauthorized();

            DistriMaxEntities db = new DistriMaxEntities();
            Producto p = db.Productos.Find(id);
            if (p == null) return NotFound();

            Categoria c = db.Categorias.Find(p.IdCategoria);

            ProductoDTO dto = new ProductoDTO();
            dto.IdProducto = p.IdProducto;
            dto.Codigo = p.Codigo;
            dto.CodigoBarras = p.CodigoBarras;
            dto.Nombre = p.Nombre;
            dto.Descripcion = p.Descripcion;
            dto.IdCategoria = p.IdCategoria;
            dto.Categoria = c != null ? c.Nombre : null;
            dto.Unidad = p.Unidad;
            dto.PorcIva = p.PorcIva;
            dto.CostoPromedio = p.CostoPromedio;
            dto.PrecioBase = p.PrecioBase;
            dto.StockMinimo = p.StockMinimo;
            dto.Activo = p.Activo;
            dto.StockTotal = Convert.ToDecimal(DbHelper.EjecutarEscalar("SELECT ISNULL(SUM(Cantidad), 0) FROM Inventario WHERE IdProducto = " + id));
            return Ok(dto);
        }

        [HttpPost]
        [Route("")]
        public IHttpActionResult Guardar(ProductoDTO p)
        {
            int idUsuario = TokenHelper.ValidarToken(Request);
            if (idUsuario == 0) return Unauthorized();

            try
            {
                if (p == null || string.IsNullOrEmpty(p.Codigo) || string.IsNullOrEmpty(p.Nombre))
                    return Ok(new RespuestaDTO { ok = false, mensaje = "Código y nombre son obligatorios" }); // AP-11: error con 200 OK
                if (p.PorcIva != 0 && p.PorcIva != 5 && p.PorcIva != 19)
                    return Ok(new RespuestaDTO { ok = false, mensaje = "El IVA debe ser 0, 5 o 19" });
                if (p.PrecioBase <= 0)
                    return Ok(new RespuestaDTO { ok = false, mensaje = "El precio base debe ser mayor a cero" });
                if (p.IdCategoria <= 0)
                    return Ok(new RespuestaDTO { ok = false, mensaje = "Debe seleccionar una categoría" });

                DistriMaxEntities db = new DistriMaxEntities();
                string codigo = p.Codigo.Trim().ToUpper();
                int idActual = p.IdProducto;

                if (db.Productos.Any(x => x.Codigo == codigo && x.IdProducto != idActual))
                    return Ok(new RespuestaDTO { ok = false, mensaje = "Ya existe un producto con el código " + codigo });

                Producto entidad;
                bool nuevo = p.IdProducto == 0;
                if (nuevo)
                {
                    entidad = new Producto();
                    entidad.CostoPromedio = p.CostoPromedio; // solo al crear; después lo maneja compras
                    db.Productos.Add(entidad);
                }
                else
                {
                    entidad = db.Productos.Find(p.IdProducto);
                    if (entidad == null) return NotFound();
                }

                entidad.Codigo = codigo;
                entidad.CodigoBarras = p.CodigoBarras;
                entidad.Nombre = p.Nombre.Trim();
                entidad.Descripcion = p.Descripcion;
                entidad.IdCategoria = p.IdCategoria;
                entidad.Unidad = string.IsNullOrEmpty(p.Unidad) ? "UND" : p.Unidad;
                entidad.PorcIva = p.PorcIva;
                entidad.PrecioBase = p.PrecioBase;
                entidad.StockMinimo = p.StockMinimo;
                entidad.Activo = p.Activo;
                db.SaveChanges();

                // Al crear, se crea el inventario en 0 en todas las bodegas... con ADO.NET, no con EF
                if (nuevo)
                {
                    DbHelper.EjecutarComando("INSERT INTO Inventario (IdBodega, IdProducto, Cantidad, CantidadReservada) SELECT IdBodega, "
                        + entidad.IdProducto + ", 0, 0 FROM Bodegas");
                }

                LogHelper.Log(idUsuario, "Productos", nuevo ? "Crear" : "Editar", entidad.Codigo + " - " + entidad.Nombre);
                return Ok(new RespuestaDTO { ok = true, mensaje = "Producto guardado", data = entidad.IdProducto });
            }
            catch (Exception ex)
            {
                LogHelper.Error(ex, Request.RequestUri.ToString());
                return Ok(new RespuestaDTO { ok = false, mensaje = "Error guardando el producto: " + ex.Message });
            }
        }

        // Precio del producto para un cliente según su lista (lo usarán Pedidos)
        [HttpGet]
        [Route("{id:int}/precio")]
        public IHttpActionResult Precio(int id, int idCliente)
        {
            if (TokenHelper.ValidarToken(Request) == 0) return Unauthorized();

            object precio = DbHelper.EjecutarEscalar("SELECT lpd.Precio FROM Clientes c INNER JOIN ListasPreciosDetalle lpd ON lpd.IdLista = c.IdLista "
                + "WHERE c.IdCliente = " + idCliente + " AND lpd.IdProducto = " + id);
            bool deLista = true;
            if (precio == null || precio == DBNull.Value)
            {
                precio = DbHelper.EjecutarEscalar("SELECT PrecioBase FROM Productos WHERE IdProducto = " + id);
                deLista = false;
            }
            return Ok(new { IdProducto = id, IdCliente = idCliente, Precio = Convert.ToDecimal(precio), DeLista = deLista });
        }
    }
}
