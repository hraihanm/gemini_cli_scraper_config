

module MeasurementExtractor
    class << self
        def extract_uom(x)
        	uom_regex = [
                /(?<!\S)(\d*[\.,]?\d+)\s?(litre)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(Liter)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(Litros)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(Galones)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(lt)[\.-]+?(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(ltr)[\.-]+?(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(lts)[\.-]+?(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(lb)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(Libras)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(Pies³)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(Pies)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(l)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(ml)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(cl)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(gr)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(grs)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(gl)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(g)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(mg)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\+?\s?(kg)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(Kilo)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(Kilogramo)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(oz)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(onz)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(slice[s]?)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(sachet[s]?)(?!\S)/i,   
                /(?<!\S)(\d*[\.,]?\d+)\s?(catridge[s]?)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(sheet[s]?)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(stick[s]?)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(bottle[s]?)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(caplet[s]?)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(roll[s]?)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(tip[s]?)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(bundle[s]?)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(pair[s]?)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(set)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(kit)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(box)(?!\S)/i,
                #/(?<!\S)(\d*[\.,]?\d+)\s?(s)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(mm)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(cm)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(cc)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(m)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(Metros)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(page[s]?)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(bag)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(mts)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(w)(?!\S)/i,
                /(?<!\S)(\d*[\.,]?\d+)\s?(v)(?!\S)/i,
            ].find {|ur| x =~ ur}

            size = $1
            unit = $2

            uom = {
        		size: (size.gsub(",", ".") rescue nil),
        		unit: (unit.capitalize rescue nil),
        	}

        	return uom
        end


        def extract_pieces(x)
            # If "x" pattern exists, return the first number before "x"
            if x =~ /(\d+)\s*[xX]\s*\d+/
                return $1.to_i
            end

            product_pieces_regex = [
                /(\d+)\s?per\s?pack(?!\S)/i,
                /(\d+)\s?pack(?!\S)/i,
                /(\d+)\s?pc[s]?(?!\S)/i,
                /(\d+)\s?unidades?(?!\S)/i,
                /(\d+)\s?und(?!\S)/i,
                /(\d+)\s?uds(?!\S)/i,
                /(\d+)\s?sobres?(?!\S)/i,
                /(\d+)\s?paq(?!\w+)(?!\S)/i,
                /(\d+)\s?tabletas?(?!\S)/i,
                /(\d+)\s?c.psulas?(?!\S)/i,
                /(\d+)\s?Gomitas?(?!\S)/i,
                /(\d+)\s?Rollos?(?!\S)/i,
                /(\d+)\s?piezas?(?!\S)/i,
                /(?<!\S)(\d+)\s?U(?!\S)/i,
                /(\d+)\s?Un(?!\S)/i,
                /(\d+)\s?Unidades(?!\S)/i,
                /(\d+)\s?Bolsitas?(?!\S)/i,
                /(\d+)\s?Hojas?(?!\S)/i,
                /(\d+)\s?Palitos?(?!\S)/i,
                /(\d+)\s?PZS?(?!\S)/i,
                /(\d+)\s?Pants?(?!\S)/i,
                /(\d+)\s?Pads?(?!\S)/i,
                /(\d+)\s?Piezas?(?!\S)/i,
                /(\d+)\s?Rollos?(?!\S)/i,
                /(\d+)\s?Saquitos?(?!\S)/i,
                /(\d+)\s?Sobres?(?!\S)/i,
                /(\d+)\s?Tabletas?(?!\S)/i,
                /(\d+)\s?Und?(?!\S)/i,
                /(\d+)\s?Uni?(?!\S)/i,
                /(\d+)\s?Unidad?(?!\S)/i,
                /(\d+)\s?Unidade?(?!\S)/i,
            ].find {|ppr| x =~ ppr}
            product_pieces = product_pieces_regex ? $1.to_i : 1
            product_pieces = 1 if product_pieces == 0

            return product_pieces
        end
    end
end