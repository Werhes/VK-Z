using System.Collections.Generic;
using System.Linq;
using Werhes.Vkz.iOS.Models;

namespace Werhes.Vkz.iOS.Converters
{
    public static class BlocksConverter
    {
        public static List<Block> ConvertToBlocks(this List<Core.Interfaces.IBlock> blocks)
        {
            return blocks.Select(b => new Block()).ToList();
        }
    }
}