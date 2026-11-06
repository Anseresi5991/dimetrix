namespace DistriMax.Common.DTOs
{
    public class DepartamentoDTO
    {
        public int IdDepartamento { get; set; }
        public string Codigo { get; set; }
        public string Nombre { get; set; }
    }

    public class CiudadDTO
    {
        public int IdCiudad { get; set; }
        public int IdDepartamento { get; set; }
        public string Codigo { get; set; }
        public string Nombre { get; set; }
    }

    public class BodegaDTO
    {
        public int IdBodega { get; set; }
        public string Nombre { get; set; }
        public string Direccion { get; set; }
        public bool Activa { get; set; }
    }

    public class ListaPrecioDTO
    {
        public int IdLista { get; set; }
        public string Nombre { get; set; }
        public bool Activa { get; set; }
    }
}
