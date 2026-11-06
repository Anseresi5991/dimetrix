using System.Web.Mvc;

namespace DistriMax.Web
{
    public class FilterConfig
    {
        // Nota: NO hay filtro global de autenticación; cada action revisa la sesión a mano (AP-09)
        public static void RegisterGlobalFilters(GlobalFilterCollection filters)
        {
            filters.Add(new HandleErrorAttribute());
        }
    }
}
