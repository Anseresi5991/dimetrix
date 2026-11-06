using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using DistriMax.Common;
using DistriMax.Common.DTOs;
using DistriMax.Web.Helpers;

namespace DistriMax.Web.Controllers
{
    public class ClientesController : Controller
    {
        public ActionResult Index(string buscar)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol == 4)
            {
                TempData["Error"] = "Tu rol no tiene acceso a clientes";
                return RedirectToAction("Index", "Home");
            }

            string url = "api/clientes";
            if (!string.IsNullOrEmpty(buscar)) url += "?buscar=" + Uri.EscapeDataString(buscar);
            List<ClienteDTO> lista = ApiHelper.Get<List<ClienteDTO>>(url);

            // El vendedor solo ve sus clientes... filtrado en el front (AP: la API los devuelve todos)
            if (rol == 3)
            {
                UsuarioDTO u = (UsuarioDTO)Session["Usuario"];
                lista = lista.Where(c => c.IdVendedor == u.IdUsuario).ToList();
            }

            ViewBag.Buscar = buscar;
            return View(lista);
        }

        public ActionResult Detalle(int id)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol == 4)
            {
                TempData["Error"] = "Tu rol no tiene acceso a clientes";
                return RedirectToAction("Index", "Home");
            }

            ClienteDTO c = ApiHelper.Get<ClienteDTO>("api/clientes/" + id);
            List<SaldoClienteDTO> saldos = ApiHelper.Get<List<SaldoClienteDTO>>("api/clientes/" + id + "/saldo");
            ViewBag.Saldo = saldos.FirstOrDefault();
            return View(c);
        }

        public ActionResult Crear()
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol == 4)
            {
                TempData["Error"] = "Tu rol no tiene acceso a clientes";
                return RedirectToAction("Index", "Home");
            }

            ClienteDTO c = new ClienteDTO();
            c.Activo = true;
            c.TipoDocumento = "NIT";
            c.DiasCredito = 30;
            c.IdLista = 2; // AP-07: "Minorista" quemado como lista por defecto
            if (rol == 3) c.IdVendedor = ((UsuarioDTO)Session["Usuario"]).IdUsuario;

            CargarCombos(null);
            return View("Form", c);
        }

        public ActionResult Editar(int id)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol == 4)
            {
                TempData["Error"] = "Tu rol no tiene acceso a clientes";
                return RedirectToAction("Index", "Home");
            }

            ClienteDTO c = ApiHelper.Get<ClienteDTO>("api/clientes/" + id);
            CargarCombos(c.IdDepartamento);
            return View("Form", c);
        }

        // AP-01 / AP-21: action gorda con reglas de negocio, permisos y validaciones
        [HttpPost]
        public ActionResult Guardar(ClienteDTO model)
        {
            if (Session["Usuario"] == null) return RedirectToAction("Login", "Account");
            int rol = (int)Session["IdRol"];
            if (rol == 4)
            {
                TempData["Error"] = "Tu rol no tiene acceso a clientes";
                return RedirectToAction("Index", "Home");
            }

            string error = "";
            if (string.IsNullOrWhiteSpace(model.RazonSocial)) error += "La razón social es obligatoria. ";
            if (string.IsNullOrWhiteSpace(model.NumeroDocumento)) error += "El número de documento es obligatorio. ";
            else if (!Utils.EsNumerico(model.NumeroDocumento)) error += "El documento solo debe tener números (sin puntos ni guiones). ";
            if (!string.IsNullOrEmpty(model.Email) && !Utils.EsEmailValido(model.Email)) error += "El email no tiene un formato válido. ";
            if (model.IdCiudad == null) error += "Selecciona la ciudad. ";
            if (model.IdVendedor == null) error += "Selecciona el vendedor. ";
            if (model.Bloqueado && string.IsNullOrWhiteSpace(model.MotivoBloqueo)) error += "Indica el motivo del bloqueo. ";

            // Reglas de permisos para crédito: solo admin (1), gerencia (2) y cartera (5) tocan cupo/días/bloqueo
            if (rol == 3)
            {
                if (model.IdCliente == 0)
                {
                    model.CupoCredito = 0;
                    model.DiasCredito = 0;
                    model.Bloqueado = false;
                }
                else
                {
                    ClienteDTO original = ApiHelper.Get<ClienteDTO>("api/clientes/" + model.IdCliente);
                    model.CupoCredito = original.CupoCredito;
                    model.DiasCredito = original.DiasCredito;
                    model.Bloqueado = original.Bloqueado;
                    model.MotivoBloqueo = original.MotivoBloqueo;
                }
            }

            // AP-07: tope de cupo quemado para gerencia/cartera (solo admin lo supera)
            if (rol != 1 && model.CupoCredito > 100000000)
                error += "El cupo máximo permitido es $100.000.000. Solicítalo al administrador. ";

            if (error != "")
            {
                ViewBag.Error = error;
                CargarCombos(model.IdDepartamento);
                return View("Form", model);
            }

            if (model.TipoDocumento == "NIT") model.DV = FormatoHelper.DigitoVerificacion(model.NumeroDocumento);
            if (model.RazonSocial != null) model.RazonSocial = model.RazonSocial.Trim();

            RespuestaDTO r = ApiHelper.Post("api/clientes", model);
            if (!r.ok)
            {
                ViewBag.Error = r.mensaje;
                CargarCombos(model.IdDepartamento);
                return View("Form", model);
            }

            TempData["Mensaje"] = "Cliente " + model.RazonSocial + " guardado correctamente";
            int id = Convert.ToInt32(r.data);
            return RedirectToAction("Detalle", new { id = id });
        }

        // Llamado por AJAX desde el formulario
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
            ViewBag.Listas = ApiHelper.Get<List<ListaPrecioDTO>>("api/general/listasprecios");
            ViewBag.Vendedores = ApiHelper.Get<List<VendedorDTO>>("api/usuarios/vendedores");
        }
    }
}
