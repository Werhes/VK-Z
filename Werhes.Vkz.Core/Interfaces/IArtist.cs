using System.Collections.Generic;

namespace Werhes.Vkz.Core.Interfaces
{
    public interface IArtist
    { 
        string Id { get; set; }
        string Name { get; set; }
        string Domain { get; set; }
        string Banner { get; set; }
        List<IBlock> Blocks { get; set; }
    }
}