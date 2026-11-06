using System;
using System.Collections.Generic;
using System.Web.Mvc;
using DistriMax.Common.DTOs;
using DistriMax.Web.Helpers;

namespace DistriMax.Web.Controllers
{
    public class ProveedoresController : Controller
    {
        public ActionResult Index(string buscar)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol != 1 && rol != 2 && rol != 4)
            {
                TempData["Error"] = "Tu rol no tiene acceso a proveedores";
                return RedirectToAction("Index", "Home");
            }

            string url = "api/proveedores";
            if (!string.IsNullOrEmpty(buscar)) url += "?buscar=" + Uri.EscapeDataString(buscar);
            RespuestaDTO r = ApiHelper.Get<RespuestaDTO>(url);
            List<ProveedorDTO> lista = ApiHelper.ConvertirData<List<ProveedorDTO>>(r.data);

            ViewBag.Buscar = buscar;
            return View(lista);
        }

        public ActionResult Crear()
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol != 1 && rol != 2 && rol != 4)
            {
                TempData["Error"] = "Tu rol no tiene acceso a proveedores";
                return RedirectToAction("Index", "Home");
            }

            CargarCombos(null);
            return View("Form", new ProveedorDTO { Activo = true, DiasPago = 30 });
        }

        public ActionResult Editar(int id)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol != 1 && rol != 2 && rol != 4)
            {
                TempData["Error"] = "Tu rol no tiene acceso a proveedores";
                return RedirectToAction("Index", "Home");
            }

            // AP-11: la API devuelve una lista con un elemento
            RespuestaDTO r = ApiHelper.Get<RespuestaDTO>("api/proveedores/" + id);
            List<ProveedorDTO> lista = ApiHelper.ConvertirData<List<ProveedorDTO>>(r.data);
            if (lista == null || lista.Count == 0)
            {
                TempData["Error"] = "Proveedor no encontrado";
                return RedirectToAction("Index");
            }

            ProveedorDTO p = lista[0];
            CargarCombos(p.IdDepartamento);
            return View("Form", p);
        }

        [HttpPost]
        public ActionResult Guardar(ProveedorDTO model)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol != 1 && rol != 2 && rol != 4)
            {
                TempData["Error"] = "Tu rol no tiene acceso a proveedores";
                return RedirectToAction("Index", "Home");
            }

            if (string.IsNullOrWhiteSpace(model.RazonSocial) || string.IsNullOrWhiteSpace(model.Nit))
            {
                ViewBag.Error = "La razón social y el NIT son obligatorios";
                CargarCombos(model.IdDepartamento);
                return View("Form", model);
            }

            RespuestaDTO r = ApiHelper.Post("api/proveedores", model);
            if (!r.ok)
            {
                ViewBag.Error = r.mensaje;
                CargarCombos(model.IdDepartamento);
                return View("Form", model);
            }

            TempData["Mensaje"] = "Proveedor guardado correctamente";
            return RedirectToAction("Index");
        }

        // AP: copia exacta de ClientesController.Ciudades
        public JsonResult Ciudades(int idDepartamento)
        {
            List<CiudadDTO> lista = ApiHelper.Get<List<CiudadDTO>>("api/general/ciudades?dpto=" + idDepartamento);
            return Json(lista, JsonRequestBehavior.AllowGet);
        }

        private void CargarCombos(int? idDepartamento)
        {
            ViewBag.Departamentos = ApiHelper.Get<List<DepartamentoDTO>>("api/general/departamentos");
            ViewBag.Ciudades = idDepartamento.HasValue
                ? ApiHelper.Get<List<CiudadDTO>>("api/general/ciudades?dpto=" + idDepartamento.Value)
                : new List<CiudadDTO>();
        }
    }
}
