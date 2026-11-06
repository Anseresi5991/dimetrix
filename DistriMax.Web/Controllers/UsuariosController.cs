using System.Collections.Generic;
using System.Web.Mvc;
using DistriMax.Common.DTOs;
using DistriMax.Web.Helpers;

namespace DistriMax.Web.Controllers
{
    public class UsuariosController : Controller
    {
        public ActionResult Index()
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            if ((int)Session["IdRol"] != 1)
            {
                TempData["Error"] = "Solo el administrador puede gestionar usuarios";
                return RedirectToAction("Index", "Home");
            }

            List<UsuarioDTO> lista = ApiHelper.Get<List<UsuarioDTO>>("api/usuarios");
            return View(lista);
        }

        public ActionResult Crear()
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            if ((int)Session["IdRol"] != 1)
            {
                TempData["Error"] = "Solo el administrador puede gestionar usuarios";
                return RedirectToAction("Index", "Home");
            }

            ViewBag.Roles = ApiHelper.Get<List<RolDTO>>("api/general/roles");
            return View("Form", new UsuarioDTO { Activo = true });
        }

        public ActionResult Editar(int id)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            if ((int)Session["IdRol"] != 1)
            {
                TempData["Error"] = "Solo el administrador puede gestionar usuarios";
                return RedirectToAction("Index", "Home");
            }

            UsuarioDTO u = ApiHelper.Get<UsuarioDTO>("api/usuarios/" + id);
            ViewBag.Roles = ApiHelper.Get<List<RolDTO>>("api/general/roles");
            return View("Form", u);
        }

        [HttpPost]
        public ActionResult Guardar(UsuarioDTO model, string ConfirmarPassword)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            if ((int)Session["IdRol"] != 1)
            {
                TempData["Error"] = "Solo el administrador puede gestionar usuarios";
                return RedirectToAction("Index", "Home");
            }

            string error = "";
            if (string.IsNullOrEmpty(model.Login)) error += "El usuario es obligatorio. ";
            if (string.IsNullOrEmpty(model.Nombre)) error += "El nombre es obligatorio. ";
            if (model.IdUsuario == 0 && string.IsNullOrEmpty(model.Password)) error += "La contraseña es obligatoria. ";
            if (!string.IsNullOrEmpty(model.Password) && model.Password != ConfirmarPassword) error += "Las contraseñas no coinciden. ";

            // No dejar que el admin se desactive a sí mismo
            UsuarioDTO actual = (UsuarioDTO)Session["Usuario"];
            if (model.IdUsuario == actual.IdUsuario && !model.Activo) error += "No puedes desactivar tu propio usuario. ";

            if (error != "")
            {
                ViewBag.Error = error;
                ViewBag.Roles = ApiHelper.Get<List<RolDTO>>("api/general/roles");
                return View("Form", model);
            }

            RespuestaDTO r = ApiHelper.Post("api/usuarios", model);
            if (!r.ok)
            {
                ViewBag.Error = r.mensaje;
                ViewBag.Roles = ApiHelper.Get<List<RolDTO>>("api/general/roles");
                return View("Form", model);
            }

            TempData["Mensaje"] = "Usuario " + model.Login + " guardado";
            return RedirectToAction("Index");
        }
    }
}
