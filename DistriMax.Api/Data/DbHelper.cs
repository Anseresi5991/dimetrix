using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace DistriMax.Api.Data
{
    public class DbHelper
    {
        public static string CadenaConexion = ConfigurationManager.ConnectionStrings["DistriMaxDB"].ConnectionString;

        public static DataTable EjecutarSP(string nombreSP, params SqlParameter[] parametros)
        {
            DataTable dt = new DataTable();
            SqlConnection cn = new SqlConnection(CadenaConexion);
            SqlCommand cmd = new SqlCommand(nombreSP, cn);
            cmd.CommandType = CommandType.StoredProcedure;
            if (parametros != null)
            {
                cmd.Parameters.AddRange(parametros);
            }
            SqlDataAdapter da = new SqlDataAdapter(cmd);
            da.Fill(dt);
            return dt;
        }

        // Para SPs que devuelven varios result sets (encabezado + detalle)
        public static DataSet EjecutarSPDataSet(string nombreSP, params SqlParameter[] parametros)
        {
            DataSet ds = new DataSet();
            SqlConnection cn = new SqlConnection(CadenaConexion);
            SqlCommand cmd = new SqlCommand(nombreSP, cn);
            cmd.CommandType = CommandType.StoredProcedure;
            if (parametros != null)
            {
                cmd.Parameters.AddRange(parametros);
            }
            SqlDataAdapter da = new SqlDataAdapter(cmd);
            da.Fill(ds);
            return ds;
        }

        public static DataTable EjecutarConsulta(string sql)
        {
            DataTable dt = new DataTable();
            SqlDataAdapter da = new SqlDataAdapter(sql, CadenaConexion);
            da.Fill(dt);
            return dt;
        }

        public static int EjecutarComando(string sql)
        {
            SqlConnection cn = new SqlConnection(CadenaConexion);
            cn.Open();
            SqlCommand cmd = new SqlCommand(sql, cn);
            int filas = cmd.ExecuteNonQuery();
            cn.Close();
            return filas;
        }

        public static object EjecutarEscalar(string sql)
        {
            SqlConnection cn = new SqlConnection(CadenaConexion);
            cn.Open();
            SqlCommand cmd = new SqlCommand(sql, cn);
            object valor = cmd.ExecuteScalar();
            cn.Close();
            return valor;
        }
    }
}
