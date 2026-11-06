using System;
using System.Collections.Generic;
using System.Web.Mvc;
using DistriMax.Common.DTOs;
using DistriMax.Web.Helpers;

namespace DistriMax.Web.Controllers
{
    public class ProductosController : Controller
    {
        public ActionResult Index(string buscar, int? idCategoria)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");

            string url = "api/productos?x=1"; // AP: el "x=1" es para no pensar en el & ...
            if (!string.IsNullOrEmpty(buscar)) url += "&buscar=" + Uri.EscapeDataString(buscar);
            if (idCategoria.HasValue) url += "&categoria=" + idCategoria.Value;

            List<ProductoDTO> lista = ApiHelper.Get<List<ProductoDTO>>(url);

            int rol = (int)Session["IdRol"];
            ViewBag.PuedeEditar = rol == 1 || rol == 2 || rol == 4;
            ViewBag.VerCostos = rol == 1 || rol == 2 || rol == 4; // el vendedor no ve costos
            ViewBag.Categorias = ApiHelper.Get<List<CategoriaDTO>>("api/categorias");
            ViewBag.Buscar = buscar;
            ViewBag.IdCategoria = idCategoria;
            return View(lista);
        }

        public ActionResult Crear()
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol != 1 && rol != 2 && rol != 4)
            {
                TempData["Error"] = "Tu rol no puede crear productos";
                return RedirectToAction("Index");
            }

            ViewBag.Categorias = ApiHelper.Get<List<CategoriaDTO>>("api/categorias");
            return View("Form", new ProductoDTO { Activo = true, Unidad = "UND", PorcIva = 19 });
        }

        public ActionResult Editar(int id)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol != 1 && rol != 2 && rol != 4)
            {
                TempData["Error"] = "Tu rol no puede editar productos";
                return RedirectToAction("Index");
            }

            ProductoDTO p = ApiHelper.Get<ProductoDTO>("api/productos/" + id);
            ViewBag.Categorias = ApiHelper.Get<List<CategoriaDTO>>("api/categorias");
            return View("Form", p);
        }

        [HttpPost]
        public ActionResult Guardar(ProductoDTO model)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol != 1 && rol != 2 && rol != 4)
            {
                TempData["Error"] = "Tu rol no puede editar productos";
                return RedirectToAction("Index");
            }

            // Regla de negocio en el front: el precio no puede ser menor al costo + 5% (AP-07)
            if (model.CostoPromedio > 0 && model.PrecioBase < model.CostoPromedio * 1.05m)
            {
                ViewBag.Error = "El precio base debe ser al menos 5% mayor al costo promedio (" + FormatoHelper.Moneda(model.CostoPromedio) + ")";
                ViewBag.Categorias = ApiHelper.Get<List<CategoriaDTO>>("api/categorias");
                return View("Form", model);
            }

            RespuestaDTO r = ApiHelper.Post("api/productos", model);
            if (!r.ok)
            {
                ViewBag.Error = r.mensaje;
                ViewBag.Categorias = ApiHelper.Get<List<CategoriaDTO>>("api/categorias");
                return View("Form", model);
            }

            TempData["Mensaje"] = "Producto " + model.Codigo + " guardado";
            return RedirectToAction("Index");
        }
    }
}
