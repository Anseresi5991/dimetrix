using System;
using System.Data.SqlClient;

namespace DistriMax.Api.Helpers
{
    public class ApiUtils
    {
        public static string DigitoVerificacion(string nit)
        {
            if (nit == null) return null;
            string limpio = "";
            foreach (char ch in nit)
            {
                if (char.IsDigit(ch)) limpio += ch;
            }
            int[] primos = new int[] { 3, 7, 13, 17, 19, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71 };
            int total = 0;
            int j = 0;
            for (int i = limpio.Length - 1; i >= 0; i--)
            {
                total += (limpio[i] - '0') * primos[j];
                j++;
            }
            int mod = total % 11;
            return (mod == 0 || mod == 1) ? mod.ToString() : (11 - mod).ToString();
        }

        public static bool SoloNumeros(string texto)
        {
            if (string.IsNullOrEmpty(texto)) return false;
            foreach (char c in texto)
            {
                if (!char.IsDigit(c)) return false;
            }
            return true;
        }

        public static SqlParameter Param(string nombre, object valor)
        {
            return new SqlParameter(nombre, valor ?? DBNull.Value);
        }
    }
}
