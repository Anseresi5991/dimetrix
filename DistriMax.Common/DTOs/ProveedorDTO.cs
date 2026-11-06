namespace DistriMax.Common.DTOs
{
    public class ProveedorDTO
    {
        public int Proveedor_Id { get; set; }
        public string Nit { get; set; }
        public string DV { get; set; }
        public string RazonSocial { get; set; }
        public string Contacto { get; set; }
        public string Telefono { get; set; }
        public string Email { get; set; }
        public int? IdCiudad { get; set; }
        public string Ciudad { get; set; }
        public int? IdDepartamento { get; set; }
        public int DiasPago { get; set; }
        public bool Activo { get; set; }
    }
}
