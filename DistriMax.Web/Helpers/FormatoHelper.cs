using System;
using System.Globalization;

namespace DistriMax.Web.Helpers
{
    public static class FormatoHelper
    {
        private static CultureInfo CO = CultureInfo.GetCultureInfo("es-CO");

        public static string Moneda(decimal valor)
        {
            return "$" + valor.ToString("#,##0", CO);
        }

        public static string Numero(decimal valor)
        {
            return valor.ToString("#,##0.##", CO);
        }

        public static string Fecha(DateTime? fecha)
        {
            return fecha.HasValue ? fecha.Value.ToString("dd/MM/yyyy") : "";
        }

        public static string FechaHora(DateTime? fecha)
        {
            return fecha.HasValue ? fecha.Value.ToString("dd/MM/yyyy hh:mm tt") : "";
        }

        // Para inputs type=number: la cultura es-CO usa coma decimal y rompe el input (bug clásico)
        public static string TextoInput(decimal valor)
        {
            return valor.ToString("0", CultureInfo.InvariantCulture);
        }

        // AP-05: tercera copia del cálculo del DV (la cuarta está en distrimax.js)
        public static string DigitoVerificacion(string nit)
        {
            if (string.IsNullOrEmpty(nit)) return "";
            int[] v = new int[] { 3, 7, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71 };
            int x = 0;
            int largo = nit.Length;
            for (int i = 0; i < largo; i++)
            {
                int y = Convert.ToInt32(nit.Substring(i, 1));
                x += y * v[largo - i - 1];
            }
            int r = x % 11;
            return (r > 1 ? 11 - r : r).ToString();
        }
    }
}
