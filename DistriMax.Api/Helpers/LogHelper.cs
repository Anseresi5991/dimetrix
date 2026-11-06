using System;
using System.Data.SqlClient;
using DistriMax.Api.Data;

namespace DistriMax.Api.Helpers
{
    public class LogHelper
    {
        public static void Log(int idUsuario, string modulo, string accion, string detalle)
        {
            try
            {
                DbHelper.EjecutarSP("sp_Log_Insertar",
                    new SqlParameter("@IdUsuario", idUsuario),
                    new SqlParameter("@Modulo", modulo),
                    new SqlParameter("@Accion", accion),
                    new SqlParameter("@Detalle", (object)detalle ?? DBNull.Value));
            }
            catch
            {
            }
        }

        public static void Error(Exception ex, string url)
        {
            try
            {
                string sql = "INSERT INTO LogErrores (Fecha, Origen, Mensaje, StackTrace, Url) VALUES (GETDATE(), 'API', '"
                    + ex.Message.Replace("'", "''") + "', '"
                    + (ex.StackTrace ?? "").Replace("'", "''") + "', '"
                    + url + "')";
                DbHelper.EjecutarComando(sql);
            }
            catch
            {
            }
        }
    }
}
