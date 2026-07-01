using System.Collections.Generic;
using Werhes.Vkz.Core.Interfaces;

namespace Werhes.Vkz.Core.Models
{
    public class Artist:IArtist
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string Domain { get; set; }
        public string Banner { get; set; }
        public List<IBlock> Blocks { get; set; }
    }
}