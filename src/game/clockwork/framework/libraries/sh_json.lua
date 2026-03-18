-- нахуй этот файл нужен
-- он тупо дополнительную нагрузку создает, ну типа понимаешь вызов луа функции, которая вызывает другую луа функцию, которая вызывает функцию из гмода, короче это просто лишняя обертка, которая не дает ничего, кроме удобства вызова функции из гмода, но я не думаю, что это стоит того, чтобы держать эту библиотеку, короче uwu

Clockwork.json = Clockwork.kernel:NewLibrary("Json")

function Clockwork.json:Encode(tableToEncode)
	return util.TableToJSON(tableToEncode)
end

function Clockwork.json:Decode(stringToDecode)
	return util.JSONToTable(stringToDecode)
end
