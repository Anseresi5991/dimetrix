using System;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace DistriMax.Common
{
    public static class Utils
    {
        public static string Md5(string texto)
        {
            MD5 md5 = MD5.Create();
            byte[] bytes = md5.ComputeHash(Encoding.UTF8.GetBytes(texto));
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < bytes.Length; i++)
            {
                sb.Append(bytes[i].ToString("x2"));
            }
            return sb.ToString();
        }
        public static string CalcularDV(string nit)
        {
            if (string.IsNullOrEmpty(nit)) return "";
            nit = nit.Replace(".", "").Replace("-", "").Replace(" ", "").Trim();
            int[] pesos = { 3, 7, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71 };
            int suma = 0;
            for (int i = 0; i < nit.Length; i++)
            {
                int digito = int.Parse(nit.Substring(nit.Length - 1 - i, 1));
                suma += digito * pesos[i];
            }
            int residuo = suma % 11;
            if (residuo > 1) return (11 - residuo).ToString();
            return residuo.ToString();
        }

        public static string FormatoMoneda(decimal valor)
        {
            return "$ " + valor.ToString("N0", new CultureInfo("es-CO"));
        }

        public static bool EsEmailValido(string email)
        {
            if (string.IsNullOrEmpty(email)) return false;
            return Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$");
        }

        public static bool EsNumerico(string valor)
        {
            long n;
            return long.TryParse(valor, out n);
        }

        public static int ToInt(object valor)
        {
            if (valor == null || valor == DBNull.Value) return 0;
            return Convert.ToInt32(valor);
        }

        public static int? ToIntNull(object valor)
        {
            if (valor == null || valor == DBNull.Value) return null;
            return Convert.ToInt32(valor);
        }

        public static decimal ToDecimal(object valor)
        {
            if (valor == null || valor == DBNull.Value) return 0;
            return Convert.ToDecimal(valor);
        }

        public static string ToStr(object valor)
        {
            if (valor == null || valor == DBNull.Value) return null;
            return valor.ToString();
        }

        public static bool ToBool(object valor)
        {
            if (valor == null || valor == DBNull.Value) return false;
            return Convert.ToBoolean(valor);
        }

        public static DateTime? ToFecha(object valor)
        {
            if (valor == null || valor == DBNull.Value) return null;
            return Convert.ToDateTime(valor);
        }

        public static string FormatoFecha(DateTime? fecha)
        {
            if (!fecha.HasValue) return "";
            return fecha.Value.ToString(Constantes.FORMATO_FECHA);
        }

        public static string Truncar(string texto, int max)
        {
            if (texto == null) return null;
            if (texto.Length <= max) return texto;
            return texto.Substring(0, max);
        }
    }
}
