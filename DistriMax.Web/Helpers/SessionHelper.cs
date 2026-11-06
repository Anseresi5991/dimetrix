using System.Web;
using DistriMax.Common.DTOs;

namespace DistriMax.Web.Helpers
{
    // Existe, pero casi ningún controller la usa: prefieren Session["..."] directo
    public class SessionHelper
    {
        public static UsuarioDTO UsuarioActual
        {
            get { return HttpContext.Current.Session["Usuario"] as UsuarioDTO; }
        }

        public static bool EstaLogueado()
        {
            return HttpContext.Current.Session["Usuario"] != null;
        }

        public static int IdRol()
        {
            UsuarioDTO u = UsuarioActual;
            return u == null ? 0 : u.IdRol;
        }
    }
}
