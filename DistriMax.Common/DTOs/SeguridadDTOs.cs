using System;

namespace DistriMax.Common.DTOs
{
    public class LoginDTO
    {
        public string Login { get; set; }
        public string Password { get; set; }
    }
    public class UsuarioDTO
    {
        public int IdUsuario { get; set; }
        public string Login { get; set; }
        public string Password { get; set; }
        public string Nombre { get; set; }
        public string Email { get; set; }
        public int IdRol { get; set; }
        public string Rol { get; set; }
        public bool Activo { get; set; }
        public DateTime? UltimoAcceso { get; set; }
        public DateTime? FechaCreacion { get; set; }
        public string Token { get; set; }
    }

    public class CambioPasswordDTO
    {
        public string Password { get; set; }
    }

    public class RolDTO
    {
        public int IdRol { get; set; }
        public string Nombre { get; set; }
    }

    public class VendedorDTO
    {
        public int IdUsuario { get; set; }
        public string Nombre { get; set; }
    }
}
