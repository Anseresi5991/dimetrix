using System;
using System.Web.Mvc;
using DistriMax.Common.DTOs;
using DistriMax.Web.Helpers;

namespace DistriMax.Web.Controllers
{
    public class AccountController : Controller
    {
        [HttpGet]
        public ActionResult Login()
        {
            if (Session["Usuario"] != null) return RedirectToAction("Index", "Home");
            return View();
        }

        // Sin [ValidateAntiForgeryToken] (deuda conocida)
        [HttpPost]
        public ActionResult Login(string usuario, string password)
        {
            if (string.IsNullOrEmpty(usuario) || string.IsNullOrEmpty(password))
            {
                ViewBag.Error = "Ingresa tu usuario y tu contraseña";
                ViewBag.Usuario = usuario;
                return View();
            }

            try
            {
                RespuestaDTO resp = ApiHelper.Post("api/auth/login", new LoginDTO { Login = usuario.Trim(), Password = password });
                if (!resp.ok)
                {
                    ViewBag.Error = resp.mensaje;
                    ViewBag.Usuario = usuario;
                    return View();
                }

                UsuarioDTO u = ApiHelper.ConvertirData<UsuarioDTO>(resp.data);

                // AP-23: todo a la sesión
                Session["Usuario"] = u;
                Session["Token"] = u.Token;
                Session["IdRol"] = u.IdRol;
                Session["NombreUsuario"] = u.Nombre;

                return RedirectToAction("Index", "Home");
            }
            catch (Exception ex)
            {
                ViewBag.Error = "No fue posible conectar con el servidor de la API. Revisa que DistriMax.Api esté corriendo. (" + ex.Message + ")";
                ViewBag.Usuario = usuario;
                return View();
            }
        }

        public ActionResult Logout()
        {
            try
            {
                ApiHelper.Post("api/auth/logout", null);
            }
            catch
            {
            }
            Session.Abandon();
            return RedirectToAction("Login");
        }
    }
}
