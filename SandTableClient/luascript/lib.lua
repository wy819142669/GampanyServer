--脚本定义的常用基础函数
--范围：主要是数学、字符串、table、文件等方面的操作，与游戏世界无关
Lib={}
Lib.tbTypeOrder = {
	["nil"] = 1, ["number"] = 2, ["string"] = 3, ["userdata"] = 4, ["function"] = 5, ["table"] = 6,
};
Lib.TYPE_COUNT = 6;	-- 类型数量
Lib.tbAwardType	= {"Exp", "Repute", "Money", "Item"};
Lib._tbCommonMetatable	= {
	__index	= function (tb, key)
		return rawget(tb, "_tbBase")[key];
	end;
};

Lib.TB_TIME_DESC	= {
	{"天", 3600 * 24};
	{"小时", 3600};
	{"分钟", 60};
	{"秒", 1};
};

Lib.Logic2Unity =512;

Lib.nRandomSeed = nil; -- Lib库随机种子
Lib.nMaxCInt = 2100000000; -- C++中int所能表达最大值
Lib.bIsDst = os.date("*t", os.time()).isdst --夏令时

--设置Lib库随机种子 by.sunduoliang
function Lib:randomseed(nSeed)
	self.nRandomSeed = nSeed;
end

--Lib库的随机函数,只支持正整数随机 by.sunduoliang
--该函数存档一些bug，因为lua语言%的算法问题，会导致有些随机数永远都不会随到。慎用
function Lib:random(nBegin, nEnd)
	self.nRandomSeed = self.nRandomSeed or GetTime();
	self.nRandomSeed = (self.nRandomSeed * 3877 + 29573) % 0xffffffff;
	if nEnd < nBegin then
		nBegin, nEnd  = nEnd, nBegin;
	end
	return nBegin + self.nRandomSeed % (nEnd - nBegin + 1)
end

function Lib:RandomWithWeights(tbWeights)
	local nTotal = 0
	for k,v in pairs(tbWeights) do
		nTotal = nTotal + v
	end
	assert(nTotal > 0, "Lib:RandomWithWeights nTotalWeight must > 0")
	local nResult = MathRandom(nTotal)
	for k,v in pairs(tbWeights) do
		if (v > 0) then
			if nTotal - v < nResult then
				return k
			else
				nTotal = nTotal - v
			end
		end
	end
end

function Lib:RandomArray(tbArray)
	local nCount = #tbArray;
	if nCount > 1 then
		local tbRand = {unpack(tbArray)};
		for i = 1, nCount do
			local nMax = #tbRand;
			local nRand = MathRandom(nMax)
			tbArray[i] = table.remove(tbRand, nRand)
		end
	end
	return tbArray;
end

-- 返回一个函数
-- 此函数 可在 1-nCount 范围内产生一个随机抽取一个数字，当nCount个数字全部抽出时，则再次从 1-nCount 范围内抽取
-- 如:
-- local fn = Lib:GetRandomSelect(3); for i = 9 do print(fn()) end;
-- 则输出循环可能为 1 3 2 2 1 3 1 3 2
function Lib:GetRandomSelect(nCount)
	local tbCurInfo = {};
	return function ()
		if #tbCurInfo <= 0 then
			for i = 1, nCount do
				tbCurInfo[i] = i;
			end
		end

		local nRandom = MathRandom(#tbCurInfo);
		local nIdx = tbCurInfo[nRandom];
		table.remove(tbCurInfo, nRandom);
		return nIdx;
	end
end

--对table进行一层的复制（不遍历下层）
--如果是连续的table，完全可以使用{unpack(tb)}，而不必使用此函数
function Lib:CopyTB1(tb)
	local tbCopy	= {};
	for k, v in pairs(tb) do
		tbCopy[k]	= v;
	end;
	return tbCopy;
end;

if EDITOR or (MODULE_GAMESERVER and SERVER_WINDOWS) then
	function Lib:CopyTB(tb)
		local tbCopy	= {};
		if type(tb) == "userdata" then
			local proxy_mt = getmetatable(tb)
			if proxy_mt and proxy_mt.__newindex == readonly_newindex then
				tb = proxy_mt.__index
			end
		end

		for k, v in pairs(tb) do
			if type(v) == "table" or type(v) == "userdata" then
				tbCopy[k]	= Lib:CopyTB(v);
			else
				tbCopy[k]	= v;
			end
		end;

		return tbCopy;
	end
else
	function Lib:CopyTB(tb)
		local tbCopy	= {};
		for k, v in pairs(tb) do
			if type(v) == "table" or type(v) == "userdata" then
				tbCopy[k]	= Lib:CopyTB(v);
			else
				tbCopy[k]	= v;
			end
		end;

		return tbCopy;
	end
end

function Lib:ChangeUserdataDeliberately(tb)
    for k, v in pairs(tb) do
        if type(v) == "userdata" then
            v.__aa_test_testkwg = 1
        end
        if type(v) == "table" then
            Lib:ChangeUserdataDeliberately(v)
        end
    end
end

function Lib:TypeId(szType)
	if self.tbTypeOrder[szType] then
		return self.tbTypeOrder[szType];
	end;
	self.TYPE_COUNT = self.TYPE_COUNT + 1;
	self.tbTypeOrder[szType] = self.TYPE_COUNT;
	return self.TYPE_COUNT;
end;

function Lib:ShowTB1(tbVar, szBlank)
	if (not szBlank) then
		szBlank = "";
	end;
	for k, v in pairs(tbVar) do
		print(szBlank.."["..self:Val2Str(k).."]	= "..tostring(v));
	end;
end;

function Lib.Comp(a, b)
	if type(a) ~= type(b) then
		return false
	end
	return a < b;
end

function Lib:ShowTB(tbVar, szBlank, tbTravelledTables)
	if (not szBlank) then
		szBlank = "";
	end;
	tbTravelledTables = tbTravelledTables or {}
	if tbTravelledTables[tbVar] then
		print("ERROE~~ InShowTB 递归引用！！！");
		return 0
	end
	tbTravelledTables[tbVar] = true
	local tbType = {};
	for k, v in pairs(tbVar) do
		local nType = self:TypeId(type(v));
		if (not tbType[nType]) then
			tbType[nType] = {n = 0, name = type(v)};
		end;
		local tbTmp = tbType[nType];
		tbTmp.n = tbTmp.n + 1;
		tbTmp[tbTmp.n] = k;
	end;
	for i = 1, self.TYPE_COUNT do
		if tbType[i] then
			local tbTmp = tbType[i];
			local szType = tbTmp.name;
			table.sort(tbTmp,self.Comp);
			for i = 1, tbTmp.n do
				local key = tbTmp[i];
				local value = tbVar[key];
				local str;
				if (type(key) == "number") then
					str = szBlank.."["..key.."]";
				else
					str = szBlank.."."..key;
				end;
				if (szType == "nil") then
					print(str.."\t= nil");
				elseif (szType == "number") then
					print(str.."\t= "..tbVar[key]);
				elseif (szType == "string") then
					print(str..'\t= "'..tbVar[key].."\"");
				elseif (szType == "function") then
					print(str.."()");
				elseif (szType == "table") then
					if (tbVar[key] == tbVar) then
						print(str.."\t= {...}(self)");
					else
						print(str..":");
						if self:ShowTB(tbVar[key], str, tbTravelledTables) == 0 then
							print("递归引用key:", key, " value:", tbVar[key])
						end
					end;
				elseif (szType == "userdata") then
					print(str.."*");
				else
					print(str.."\t= "..tostring(tbVar[key]));
				end;
			end;
		end;
	end;
	tbTravelledTables[tbVar] = nil
end;

function Lib:LogErrTB(tbVar, szBlank, nCount)
	if (not szBlank) then
		szBlank = ""
	end
	nCount = nCount or 0
	if nCount > 10000 then
		LogErr("ERROE~~ 层数太多，超过了1万次，防止死循环！！！！")
		return 0
	end
	local tbType = {}
	for k, v in pairs(tbVar) do
		local nType = self:TypeId(type(v))
		if (not tbType[nType]) then
			tbType[nType] = {n = 0, name = type(v)}
		end
		local tbTmp = tbType[nType]
		tbTmp.n = tbTmp.n + 1
		tbTmp[tbTmp.n] = k
	end
	for i = 1, self.TYPE_COUNT do
		if tbType[i] then
			local tbTmp = tbType[i]
			local szType = tbTmp.name
			table.sort(tbTmp, self.Comp)
			for i = 1, tbTmp.n do
				local key = tbTmp[i]
				local value = tbVar[key]
				local str
				if (type(key) == "number") then
					str = szBlank.."["..key.."]"
				else
					str = szBlank.."."..key
				end
				if (szType == "nil") then
					LogErr(str.."\t= nil")
				elseif (szType == "number") then
					LogErr(str.."\t= "..tbVar[key])
				elseif (szType == "string") then
					LogErr(str..'\t= "'..tbVar[key].."\"")
				elseif (szType == "function") then
					LogErr(str.."()")
				elseif (szType == "table") then
					if (tbVar[key] == tbVar) then
						LogErr(str.."\t= {...}(self)")
					else
						LogErr(str..":")
						self:LogErrTB(tbVar[key], str, nCount+1)
					end
				elseif (szType == "userdata") then
					LogErr(str.."*")
				else
					LogErr(str.."\t= "..tostring(tbVar[key]))
				end
			end
		end
	end
end

function Lib:LogTB(tbVar, szBlank, nCount)
	if (not szBlank) then
		szBlank = "";
	end;
	nCount = nCount or 0;
	if nCount > 10000 then
		Log("ERROE~~ 层数太多，超过了1万次，防止死循环！！！！");
		return 0;
	end
	local tbType = {};
	for k, v in pairs(tbVar) do
		local nType = self:TypeId(type(v));
		if (not tbType[nType]) then
			tbType[nType] = {n = 0, name = type(v)};
		end;
		local tbTmp = tbType[nType];
		tbTmp.n = tbTmp.n + 1;
		tbTmp[tbTmp.n] = k;
	end;
	for i = 1, self.TYPE_COUNT do
		if tbType[i] then
			local tbTmp = tbType[i];
			local szType = tbTmp.name;
			table.sort(tbTmp, self.Comp);
			for i = 1, tbTmp.n do
				local key = tbTmp[i];
				local value = tbVar[key];
				local str;
				if (type(key) == "number") then
					str = szBlank.."["..key.."]";
				else
					str = szBlank.."."..key;
				end;
				if (szType == "nil") then
					Log(str.."\t= nil");
				elseif (szType == "number") then
					Log(str.."\t= "..tbVar[key]);
				elseif (szType == "string") then
					Log(str..'\t= "'..tbVar[key].."\"");
				elseif (szType == "function") then
					Log(str.."()");
				elseif (szType == "table") then
					if (tbVar[key] == tbVar) then
						Log(str.."\t= {...}(self)");
					else
						Log(str..":");
						self:LogTB(tbVar[key], str, nCount+1);
					end;
				elseif (szType == "userdata") then
					Log(str.."*");
				else
					Log(str.."\t= "..tostring(tbVar[key]));
				end;
			end;
		end;
	end;
end;

function Lib:LogData(...)
	local arg = {...};

	for _, value in ipairs(arg) do
		if type(value) == "table" then
			Lib:LogTB(value);
			Log("----------------------------");
		else
			Log(value);
		end
	end
end

-- 判断tableA中是否包含value
function Lib:IsContain(tableA, value)
	for _, v in pairs(tableA) do
		if (v == value) then
			return true
		end
	end
	return false
end

-- 获取两个table的差值，在tableA中，但没有在tableB中的子集(tableA - tableB)
function Lib:GetSubTable(tbA, tbB)
	local funContain = function(tbTemp, value)
		for _, v in pairs(tbTemp) do
			if (v == value) then
				return true
			end
		end
		return false
	end
	local tbSub = {}
	for _, v in pairs(tbA) do
		if (not funContain(tbB, v)) then
			table.insert(tbSub, v)
		end
	end
	return tbSub
end

-- 比较两个table是否相同（用于key相同的表）
function Lib:CompareTB(tableA, tableB)
	for k,v in pairs(tableA) do
		if tableB[k] ~= v then
			return false;
		end
	end

	return true;
end

function Lib:CountTB(tbVar)
	local nCount = 0;
	for _, _ in pairs(tbVar) do
		nCount	= nCount + 1;
	end;
	return nCount;
end;

function Lib:HaveCountTB(tbVar)
	for _, _ in pairs(tbVar) do
		return true;
	end;

	return false;
end;

-- 合并2个表，用于下标默认的表
function Lib:MergeTable(tableA, tableB)
	for _, item in ipairs(tableB) do
		tableA[#tableA + 1] = item;
	end

	return tableA;
end;

function Lib:StrVal2Str(szVal)
	szVal	= string.gsub(szVal, "\\", "\\\\");
	szVal	= string.gsub(szVal, "\"", '\\"');
	szVal	= string.gsub(szVal, "\n", "\\n");
	szVal	= string.gsub(szVal, "\r", "\\r");
	--szVal	= string.format("%q", szVal);
	return "\""..szVal.."\"";
end;

-- 过滤字符串中的指定字符
-- tbReplacedChars是所有要被过滤的字符table
-- szReplaceWith是用来替换过滤字符的字符，默认为空字符
function Lib:StrFilterChars(szOrg, tbReplacedChars, szReplaceWith)
	szReplaceWith = szReplaceWith or ""
	local szTmp = szOrg
	for _,c in pairs(tbReplacedChars) do
		szTmp = string.gsub(szTmp, c, szReplaceWith)
	end
	return szTmp
end

-- 去除指定字符串首尾指定字符
function Lib:StrTrim(szDes, szTrimChar)
	if (not szTrimChar) then
		szTrimChar = " ";
	end

	if (string.len(szTrimChar) ~= 1) then
		return szDes;
	end

	local szRet, nCount = string.gsub(szDes, "("..szTrimChar.."*)([^"..szTrimChar.."]*.*[^"..szTrimChar.."])("..szTrimChar.."*)", "%2");
	if (nCount == 0) then
		return "";
	end

	return szRet;
end

-- 字符串分隔
function Lib:StrSplit(szDes, szReps)
	local tbContents = {}
    string.gsub(szDes, table.concat({"[^", szReps, "]+"}),
    	function (szContent)
        	table.insert(tbContents, szContent)
    	end)
    return tbContents
end

function Lib:Val2Str(var, szBlank)
	local szType	= type(var);
	if (szType == "nil") then
		return "nil";
	elseif (szType == "number") then
		return tostring(var);
	elseif (szType == "string") then
		return self:StrVal2Str(var);
	elseif (szType == "function") then
		local szCode	= string.dump(var);
		local arByte	= {string.byte(szCode, i, #szCode)};
		szCode	= "";
		for i = 1, #arByte do
			szCode	= szCode..'\\'..arByte[i];
		end;
		return 'loadstring("' .. szCode .. '")';
	elseif (szType == "table") then
		if not szBlank then
			szBlank	= "";
		end;
		local szTbBlank	= szBlank .. "  ";
		local szCode	= "";
		for k, v in pairs(var) do
			local szPair	= szTbBlank.."[" .. self:Val2Str(k) .. "]	= " .. self:Val2Str(v, szTbBlank) .. ",\n";
			szCode	= szCode .. szPair;
		end;
		if (szCode == "") then
			return "{}";
		else
			return "\n"..szBlank.."{\n"..szCode..szBlank.."}";
		end;
	elseif szType == "boolean" then
		return var and "true" or "false";
	else	--if (szType == "userdata") then
		return "\"" .. tostring(var) .. "\"";
	end;
end;

function Lib:Str2Val(szVal)
	return assert(loadstring("return "..szVal))();
end;


function Lib:NewClass(tbBase, ...)
	local arg = {...};
	local tbNew	= { _tbBase = tbBase };							-- 基类
	setmetatable(tbNew, self._tbCommonMetatable);
	local tbRoot = tbNew;
	local tbInit = {};
	repeat										-- 寻找最基基类
		tbRoot = rawget(tbRoot, "_tbBase");
		local fnInit = rawget(tbRoot, "init");
		if (type(fnInit) == "function") then
			table.insert(tbInit, fnInit);		-- 放入构造函数栈
		end
	until (not rawget(tbRoot, "_tbBase"));
	for i = #tbInit, 1, -1 do
		local fnInit = tbInit[i];
		if fnInit then
			fnInit(tbNew, unpack(arg));			-- 从底向上调用构造函数
		end
	end
	return tbNew;
end

function Lib:ConcatStr(tbStrElem, szSep)
	if (not szSep) then
		szSep = ",";
	end
	return table.concat(tbStrElem, szSep);
end

function Lib:SplitStr(szStrConcat, szSep)
	if (not szSep) then
		szSep = ",";
	end;
	local tbStrElem = {};

	--特殊转义字符指定长度
	local tbSpeSep = {
		["%."] = 1;
	};

	local nSepLen = tbSpeSep[szSep] or #szSep;
	local nStart = 1;
	local nAt = string.find(szStrConcat, szSep);
	while nAt do
		tbStrElem[#tbStrElem+1] = string.sub(szStrConcat, nStart, nAt - 1);
		nStart = nAt + nSepLen;
		nAt = string.find(szStrConcat, szSep, nStart);
	end
	tbStrElem[#tbStrElem+1] = string.sub(szStrConcat, nStart);
	return tbStrElem;
end

function Lib:SplitStr2Num(szStrConcat, szSep)
	local tbResult = self:SplitStr(szStrConcat, szSep)
	local tbNumResult = {}
	for nIndex, szTmp in ipairs(tbResult) do
		tbNumResult[nIndex] = tonumber(szTmp)
	end
	return tbNumResult
end

function Lib:GetTableFromString(szValue, bKeyNotNumber, bValueNotNumber)
	local tbResult = {};
	local tbLines = Lib:SplitStr(szValue, ";");
	for _, szCell in ipairs(tbLines) do
		if szCell ~= "" then
			local Key, Value = string.match(szCell, "^([^|]+)|([^|]+)$");
			if not Key then
				return;
			end

			if not bKeyNotNumber then
				Key = tonumber(Key)
			end
			if not bValueNotNumber then
				Value = tonumber(Value);
			end

			if not Key or not Value then
				return;
			end

			tbResult[Key] = Value;
		end
	end

	return tbResult;
end

--TODO 缺的自己加上去
function Lib:GetAwardDesCount(tbAllAward, pPlayer)
	local nFaction = pPlayer.nFaction;
	local nFactionSect = pPlayer.nFactionSect
	local nSex = Player:GetPlayerSex(pPlayer)
	local tbAwardDes = {};
for nIndex, tbAward in pairs(tbAllAward) do
		local tbDes = {};
		local szAwardType = tbAward[1];
		local nAwardType = Player.AwardType[tbAward[1]];
		if nAwardType == Player.award_type_item or nAwardType == Player.award_type_item_Unsafe then
			tbDes.szName = KItem.GetItemShowInfo(tbAward[2], nFaction, nFactionSect, nSex)
			tbDes.nCount = tbAward[3];
			tbDes.szUnit = "个";
		elseif nAwardType == Player.award_type_money then
			tbDes.szName = Shop:GetMoneyName(szAwardType);
			tbDes.szName = tbDes.szName or "";
			tbDes.nCount = tbAward[2];
			tbDes.szUnit = "个";
		elseif nAwardType == Player.award_type_kin_found then
			tbDes.szName = "帮会资金";
			tbDes.nCount = tbAward[2];
			tbDes.szUnit = "两";
		elseif nAwardType == Player.award_type_equip_debris then
			tbDes.szName = KItem.GetItemShowInfo(tbAward[2], nFaction, nFactionSect, nSex)
			tbDes.szName = tbDes.szName .. "碎片"
			tbDes.nCount = 1
			tbDes.szUnit = "个"
		elseif nAwardType == Player.award_type_basic_exp then
			tbDes.szName = "经验";
			tbDes.nCount = tbAward[2] * pPlayer.GetBaseAwardExp();
			tbDes.szUnit = "点";
		elseif nAwardType == Player.award_type_faction_honor then
			tbDes.szName = "门派荣誉";
			tbDes.nCount = tbAward[2];
			tbDes.szUnit = "点";
		elseif nAwardType == Player.award_type_battle_honor then
			tbDes.szName = "战场荣誉";
			tbDes.nCount = tbAward[2];
			tbDes.szUnit = "点";
		elseif nAwardType == Player.award_type_zone_battle_honor then
			tbDes.szName = "跨服战场荣誉";
			tbDes.nCount = tbAward[2];
			tbDes.szUnit = "点";
		elseif nAwardType == Player.award_type_domain_battle then
			tbDes.szName = "攻城战荣誉";
			tbDes.nCount = tbAward[2];
			tbDes.szUnit = "点";
		elseif nAwardType == Player.award_type_contrib then
			tbDes.szName = "贡献";
			tbDes.nCount = tbAward[2];
			tbDes.szUnit = "点";
		end

		if next(tbDes) then
			tbAwardDes[nIndex] = tbDes;
		end
	end

	return tbAwardDes;
end

function Lib:Str2LunStr(szTxtStr)
    local szLunStr = string.gsub(szTxtStr, "\\n", "\n");
    return szLunStr;
end

--"1,2|1,2">>>>>>{{1,2},{1,2}}
function Lib:GetTabFromString1(str)
	local result ={}
	local tbLines = Lib:SplitStr(str, "|");
	for _, szCell in ipairs(tbLines) do
		local tbItemInfo = Lib:SplitStr(szCell, ",");
		table.insert(result, tbItemInfo);
	end
	return result
end

function Lib:GetAwardFromString(szAwardInfo)
	local tbResult = {};
	szAwardInfo = string.gsub(szAwardInfo, "\"", "");
	local tbLines = Lib:SplitStr(szAwardInfo, ";");
	if tbLines[#tbLines] == "" then
		tbLines[#tbLines] = nil;
	end

	if not tbLines or #tbLines < 1 then
		--Log("Lib:GetAwardFromString(szAwardInfo) fail ?? ", szAwardInfo);
		return {};
	end

	for _, szCell in ipairs(tbLines) do
		if szCell ~= "" then
			local tbItemInfo = Lib:SplitStr(szCell, "|");
			if tbItemInfo[#tbItemInfo] == "" then
				tbItemInfo[#tbItemInfo] = nil;
			end

			if tbItemInfo and #tbItemInfo >= 2 then
				for k, v in ipairs(tbItemInfo) do
					local nv = tonumber(v);
					if nv then
						tbItemInfo[k] = nv;
					end
				end
				table.insert(tbResult, tbItemInfo);
			--else
			--	Log("Lib:GetAwardFromString(szAwardInfo) fail ?? ", szCell, szAwardInfo);
			end
		end
	end
	return tbResult;
end

function Lib:IsTrue(var)
	return (var ~= nil and var ~= 0 and var ~= false and var ~= "false" and var ~= "");
end;

function Lib:IsEmptyStr(var)
    if type(var) ~= "string" or var == "" or var == " " then
        return true;
    end

    return false;
end

-- 按照统一的格式回调函数
function Lib:CallBack(tbCallBack)
	local varFunc	= tbCallBack[1];
	local szType	= type(varFunc);

	local function InnerCall()
		if (szType == "function") then	-- 直接指定了函数及参数
			return	tbCallBack[1](unpack(tbCallBack, 2));
		elseif (szType == "string") then	-- 按照字符串的方式指定了函数
			local fnFunc, tbSelf	= KLib.GetValByStr(varFunc);
			if (fnFunc) then
				if (tbSelf) then
					return fnFunc(tbSelf, unpack(tbCallBack, 2));
				else
					return fnFunc(unpack(tbCallBack, 2));
				end;
			else
				return false, "Wrong name string : "..varFunc;
			end;
		end;
	end

	local tbRet	= {xpcall(InnerCall, Lib.ShowStack)};

	return unpack(tbRet);
end;


function Lib:SafeCall( func )
	xpcall(func, Lib.ShowStack)
end


function Lib.ShowStack(s)
	LogErr(debug.traceback(s,2));
	return s;
end

-- 检查一个Table是否另一个Table的派生Table
function Lib:IsDerived(tbThis, tbBase)
	if (not tbThis) or (not tbBase) then
		return	0;
	end;
	repeat
		local pBase = rawget(tbThis, "_tbBase");
		if (pBase == tbBase) then
			return	1;
		end
		tbThis = pBase;
	until (not tbThis);
	return	0;
end

--是否是官服,参数是不带zoneID的
function Lib:IsMainServer(nServerId)
	if nServerId < 1500 or nServerId > 1900 then
		return true
	end
	return false
end

-- 得到当天0点0时的秒数
function Lib:GetTodayZeroHour(nTime)
    local nTimeNow = nTime or GetTime();
    if MODULE_GAMECLIENT then
		nTimeNow = nTimeNow +  GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end
    local tbTime = os.date("*t", nTimeNow);

    return nTimeNow - (tbTime.hour * 3600 + tbTime.min * 60 + tbTime.sec);
end

-- 得到本周0点0时的秒数
function Lib:GetWeekZeroHour(nTime)
	local nTimeNow = nTime or GetTime();
	if MODULE_GAMECLIENT then
		nTimeNow = nTimeNow +  GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end

	local nW        = tonumber(os.date("%w", nTimeNow));
    local tbTime    = os.date("*t", nTimeNow);

    if nW == 0 then
        nW = 7;
    end

    nW = nW - 1;
    return nTimeNow - (nW * 86400 + tbTime.hour * 3600 + tbTime.min * 60 + tbTime.sec)
end

function Lib:GetNextHour(nTime)
	local nTimeNow = nTime or GetTime() - (self.bIsDst and 3600 or 0);
    --服务器时间为准
    local tbTime = os.date("*t", nTimeNow)
    local curSec = tbTime.hour*3600 + tbTime.min * 60 + tbTime.sec
    local nextHour = (tbTime.hour+1) * 3600
    local addTime = nextHour-curSec
    return nTimeNow+addTime
end

function Lib:GetLastHour(nTime)
	local nTimeNow = nTime or GetTime() - (self.bIsDst and 3600 or 0);
    local tbTime = os.date("*t", nTimeNow)
    local curSec = tbTime.hour*3600 + tbTime.min * 60 + tbTime.sec
    local lastHour = tbTime.hour * 3600
    local addTime = lastHour-curSec
    return nTimeNow+addTime
end


-- 今周过的多少秒
function Lib:GetLocalWeekTime()
    local nTimeNow  = GetTime();

    if MODULE_GAMECLIENT then
		nTimeNow = nTimeNow +  GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end
    local nW        = tonumber(os.date("%w", nTimeNow));
    local tbTime    = os.date("*t", nTimeNow);
    if nW == 0 then
        nW = 7;
    end

    nW = nW - 1;
    return nW * 86400 + tbTime.hour * 3600 + tbTime.min * 60 + tbTime.sec;
end

-- 功能:	把秒数转换为 nHour小时，nMinute分钟, nSecond秒
-- 参数:	nSecondTime秒
-- 返回值:	nHour小时，nMinute分钟, nSecond秒
function Lib:TransferSecond2NormalTime(nSecondTime)
	local nHour, nMinute, nSecond = 0, 0, 0;

	if (nSecondTime >= 3600) then
		nHour = math.floor(nSecondTime / 3600);
		nSecondTime = math.floor(nSecondTime % 3600)
	end

	if (nSecondTime >= 60) then
		nMinute = math.floor(nSecondTime / 60);
		nSecondTime = math.floor(nSecondTime % 60)
	end
	nSecond	= math.floor(nSecondTime);
	return nHour, nMinute, nSecond;
end

-- 功能:	把一个长度不超过4位的阿拉伯数字整数转化成为中文数字
-- 参数:	nDigit, (0 <= nDigit) and (nDigit < 10000)
-- 返回值:	中文数字
function Lib:Transfer4LenDigit2CnNum(nDigit)
	if TRANSLATE_LANGUAGE == "vet" then
        return nDigit -- 越南文不转中文数字
    end
	local tbCnNum  = self.tbCnNum;
	if not tbCnNum then
		tbCnNum =
		{
			[1] 	= "一",
			[2]	 	= "二",
			[3]		= "三",
			[4]		= "四",
			[5] 	= "五",
			[6]		= "六",
			[7] 	= "七",
			[8]		= "八",
			[9] 	= "九",
		};
		self.tbCnNum = tbCnNum;
	end
	local tb4LenCnNum = self.tb4LenCnNum;
	if not tb4LenCnNum then
		tb4LenCnNum =
		{
			[1]		= "",
			[2]		= "十",
			[3]		= "百",
			[4]		= "千",
		};
		self.tb4LenCnNum = tb4LenCnNum;
	end

	local nDigitTmp	= nDigit;			-- 临时变量
	local nModel	= 0;				-- nDigit中每一位数字的值
	local nPreNum	= 0;				-- nDigit低一位数字的值
	local bOneEver	= false;			-- 做标记,当前是否出现过不为0的值
	local szCnNum	= "";				-- 保存中文数字的变量
	local szNumTmp	= "";				-- 临时变量

	if (nDigit == 0) then
		return;
	end

	if (nDigit >= 10 and nDigit < 20) then
		if (nDigit == 10) then
			szCnNum = tb4LenCnNum[2];
		else
			szCnNum = tb4LenCnNum[2]..tbCnNum[math.floor(nDigit % 10)];
		end
		return szCnNum;
	end

	for i = 1, #tb4LenCnNum do
		szNumTmp	= "";
		nModel		= math.floor(nDigitTmp % 10);	-- 取得nDigit当前位上的值
		if (nModel ~= 0) then
			szNumTmp = szNumTmp..tbCnNum[nModel]..tb4LenCnNum[i];
			if (nPreNum == 0 and bOneEver) then
				szNumTmp = szNumTmp.."零";
			end
			bOneEver = true;
		end
		szCnNum	= szNumTmp..szCnNum;

		nPreNum	= nModel;
		nDigitTmp	= math.floor(nDigitTmp / 10);
		if (nDigitTmp == 0) then
			break;
		end
	end

	return szCnNum;
end

-- 功能:	把一个阿拉伯数字nDigit转化成为中文数字
-- 参数:	nDigit,nDigit是整数,并且(1万亿 > nDigit) and (nDigit > -1万亿)
-- 返回值:	中文数字
function Lib:TransferDigit2CnNum(nDigit)
	local tbModelUnit = {
		[1]	= "";
		[2]	= "万";
		[3] = "亿";
	};

	local nDigitTmp = nDigit;	-- 临时变量,
	local n4LenNum	= 0;		-- 每一次对nDigit取4位操作,n4LenNum表示取出来的数的值
	local nPreNum	= 0;		-- 记录前一次进行取4位操作的n4LenNum的值
	local szCnNum	= "";		-- 就是所要求的结果
	local szNumTmp	= "";		-- 临时变量,每取四位的操作中得到的中文数字

	if (nDigit == 0) then
		szCnNum = "零";
		return szCnNum;
	end

	if (nDigit < 0) then
		nDigitTmp = math.floor(nDigit * (-1));
		szCnNum	  = "负";
	end

	-- 分别从个,万,亿三段考虑,因为nDigit的值小于1万亿,所以每一段都不超过4位
	for i = 1, #tbModelUnit do
		szNumTmp	= "";
		n4LenNum	= math.floor(nDigitTmp % 10000);
		if (n4LenNum ~= 0) then
			szNumTmp = self:Transfer4LenDigit2CnNum(n4LenNum);					-- 得到该四位的中文表达式
			szNumTmp = szNumTmp..tbModelUnit[i];								-- 加上单位
			if ((nPreNum > 0 and nPreNum < 1000) or								-- 两个数字之间有0,所以要加"零"
				(math.floor(n4LenNum % 10) == 0 and i > 1)) then
				szNumTmp	= szNumTmp.."零";
			end
		end
		szCnNum	= szNumTmp..szCnNum;

		nPreNum	= n4LenNum;
		nDigitTmp = math.floor(nDigitTmp / 10000);
		if (nDigitTmp == 0) then
			break;
		end
	end

	return szCnNum;
end

-- 功能:	把一个阿拉伯数字nDigit转化成为为带阿拉伯数字同时又带万，亿的结合字
-- 参数:	nDigit,nDigit是整数,并且(1万亿 > nDigit) and (nDigit > -1万亿)
-- 返回值:	阿拉伯数字同时又带万，亿的结合字
function Lib:TransferDigit2CnNumOverMillion(nDigit)
	local tbModelUnit = {
		[1]	= "";
		[2]	= "万";
		[3] = "亿";
	};

	local nDigitTmp = nDigit;	-- 临时变量,
	local szCnNum	= "";		-- 就是所要求的结果

	if (nDigit == 0) then
		szCnNum = "0";
		return szCnNum;
	end

	if (nDigit < 0) then
		nDigitTmp = math.floor(nDigit * (-1));
		szCnNum	  = "-";
	end

	local tbDuanNum = {}
	for i = 1, #tbModelUnit do
		table.insert(tbDuanNum, nDigitTmp % 10000)
		nDigitTmp = math.floor(nDigitTmp/ 10000)

	end
	for i= #tbModelUnit,1,-1 do
		if tbDuanNum[i] and tbDuanNum[i] >= 1 then
			szCnNum = szCnNum .. tbDuanNum[i] .. tbModelUnit[i]
		end
	end
	return szCnNum;
end

-- 功能:	把阿拉伯数字表示的小时转换成中文的小时
-- 参数:	nHour,小时,(1万亿 > nHour) and (nHour > -1万亿)
-- 返回值:	szXiaoshi小时
function Lib:GetCnTime(nHour)
	local szXiaoshi	= "";
	local szShichen	= "";
	local nDigit	= math.floor(nHour);

	if (nHour - nDigit == 0.5 and nDigit > 0) then
		szXiaoshi	= self:TransferDigit2CnNum(nDigit).."个半小时";
	elseif (nHour - nDigit == 0.5) then
		szXiaoshi	= "半个小时";
	else
		szXiaoshi	= self:TransferDigit2CnNum(nDigit).."个小时";
	end

	return szXiaoshi;
end

-- 将秒数转为时间描述字符串，短描述
function Lib:TimeDesc(nSec)
	nSec = math.max(0, nSec)
	if (nSec < 60) then
		return string.format("%d秒", nSec);
	elseif (nSec < 3600) then	-- 小于1小时
		return string.format("%d分%d秒", nSec / 60, math.mod(nSec, 60));
	elseif (nSec < 3600 * 24) then	-- 小于1天
		return  string.format( nSec % 3600 == 0 and "%d小时" or "%.1f小时", nSec / 3600)
	else
		return string.format(nSec % (3600 * 24) == 0 and "%d天" or "%.1f天", nSec / (3600 * 24));
	end
end

function Lib:TimeDesc2(nSec)
	if (nSec < 3600) then	-- 小于1小时
		return string.format("%d分%d秒", nSec / 60, math.mod(nSec, 60));
	elseif (nSec < 3600 * 24) then	-- 小于1天
		return string.format("%d小时%d分", nSec / 3600, (nSec % 3600) / 60);
	else
		return string.format("%d天%d小时", nSec / (3600 * 24), (nSec % (3600 * 24) ) / 3600);
	end
end

function Lib:TimeDesc3(nSec)
	if nSec < 3600 then
		return string.format("%02d:%02d", nSec % 3600 / 60, nSec % 60);
	else
		return string.format("%02d:%02d:%02d", nSec / 3600, nSec % 3600 / 60, nSec % 60);
	end
end

function Lib:TimeDesc4(nSec)
	if nSec < 60 then
		return string.format("%d\"", nSec % 60);
	else
		return string.format("%d\'%d\"", nSec / 60, nSec % 60);
	end
end

function Lib:TimeDesc5(nSec)
	local nHour,nMin = self:TransferSecond2NormalTime(nSec)

	if nHour > 0 then
		if math.floor(nHour / 24) > 0 then
			return string.format("%d天%d小时%d分",math.floor(nHour / 24),nHour % 24 ,nMin);
		else
			return string.format("%d小时%d分",nHour,nMin);
		end
	end

	return string.format("%d分",nMin);
end

-- 将秒数转为时间描述字符串，短描述
function Lib:TimeDesc6(nSec)
	nSec = math.max(0, nSec)
	if (nSec < 60) then
		return string.format("%d秒", nSec);
	elseif (nSec < 3600) then	-- 小于1小时
		return string.format("%d分%d秒", nSec / 60, math.mod(nSec, 60))
	elseif (nSec < 3600 * 24) then	-- 小于1天
		return  string.format("%d小时", math.floor(nSec / 3600))
	else
		return string.format("%d天", math.floor(nSec/(3600 * 24)))
	end
end

function Lib:TimeDesc7(nTime)
	nTime = math.max(0, nTime)
	if MODULE_GAMECLIENT then
		nTime = nTime + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0);
	end

	local tbTime    = os.date("*t", nTime);
	return string.format("%s年%s月%s日%s时",tbTime.year,tbTime.month,tbTime.day,tbTime.hour)
end


function Lib:TimeDesc8(nSec)
	if (nSec < 3600) then	-- 小于1小时
		return string.format("%d分%d秒", nSec / 60, math.mod(nSec, 60));
	else	-- 大于1小时
		return string.format("%d小时%d分", nSec / 3600, (nSec % 3600) / 60);
	end
end

function Lib:TimeDesc9( nTime )
	nTime = math.max(0, nTime)
	if MODULE_GAMECLIENT then
		nTime = nTime + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0);
	end
	local tbTime    = os.date("*t", nTime);
	return string.format("%s年%s月%s日 %s:%s:%s",tbTime.year,tbTime.month,
		tbTime.day,tbTime.hour, tbTime.min, tbTime.sec)
end

--年月日 00:00:00
function Lib:TimeDesc11( nTime )
	nTime = math.max(0, nTime)
	if MODULE_GAMECLIENT then
		nTime = nTime + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0);
	end
	local tbTime    = os.date("*t", nTime);
	return string.format("%s年%s月%s日 %02d:%02d:%02d",tbTime.year,tbTime.month,
		tbTime.day,tbTime.hour, tbTime.min, tbTime.sec)
end


function Lib:TimeDesc10( nTime )
	nTime = math.max(0, nTime)
	if MODULE_GAMECLIENT then
		nTime = nTime + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0);
	end

	local tbTime    = os.date("*t", nTime);
	return string.format("%s年%s月%s日",tbTime.year,tbTime.month,tbTime.day)
end

function Lib:TimeDesc12(nSec)
    if (nSec < 3600) then
        if nSec < 60 then
            return string.format("%d秒", nSec % 60)
        else
            if nSec % 60 ~= 0 then
                return string.format("%d分%d秒", nSec / 60, nSec % 60)
            else
                return string.format("%d分钟", nSec / 60)
            end
        end
    else
        if (nSec % 3600) >= 60 then
            return string.format("%d小时%d分钟", nSec / 3600, (nSec % 3600) / 60)
        else
            return string.format("%d小时", nSec / 3600)
        end
    end
end

function Lib:TimeDesc13( nTime )
	nTime = math.max(0, nTime)
	if MODULE_GAMECLIENT then
		nTime = nTime + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0);
	end

	local tbTime    = os.date("*t", nTime);
	return string.format("%s月%s日", tbTime.month, tbTime.day)
end

-- 这个和Lib:TimeDesc7的区别只是这里没有加上是时区差
function Lib:TimeDesc14(nTime)
	nTime = math.max(0, nTime) - (self.bIsDst and 3600 or 0)
	local tbTime    = os.date("*t", nTime);
	return string.format("%s年%s月%s日%s时",tbTime.year,tbTime.month,tbTime.day,tbTime.hour)
end

function Lib:TimeDesc15( nTime )
	nTime = math.max(0, nTime)
	if MODULE_GAMECLIENT then
		nTime = nTime + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0);
	end

	local tbTime    = os.date("*t", nTime);
	return string.format("%s/%s/%s %02d:%02d",tbTime.year,tbTime.month,tbTime.day,tbTime.hour,tbTime.min)
end

-- 将秒数转为时间描述字符串，精确值
function Lib:TimeFullDesc(nSec, nPrecision)
	nPrecision = nPrecision or #self.TB_TIME_DESC;
	local szMsg	= "";
	local nLastLevel	= #self.TB_TIME_DESC;
	for nLevel = 1, nPrecision do
		local tbTimeDesc = self.TB_TIME_DESC[nLevel];
		local nUnit	= tbTimeDesc[2];
		if (nSec >= nUnit or (nUnit == 1 and szMsg == "")) then
			if (nLevel > nLastLevel + 1) then
				szMsg	= szMsg .. "零";
			end
			szMsg	= szMsg .. math.floor(nSec / nUnit) .. tbTimeDesc[1];
			nSec	= math.mod(nSec, nUnit);
			nLastLevel	= nLevel;
		end
	end
	return szMsg;
end

-- 将秒数转为时间描述字符串，精确值
function Lib:TimeFullDescEx(nSec)
	local szMsg	= "";
	local nLastLevel	= #self.TB_TIME_DESC;
	for nLevel, tbTimeDesc in ipairs(self.TB_TIME_DESC) do
		local nUnit	= tbTimeDesc[2];
		if (nSec >= nUnit or (nUnit == 1 and szMsg == "")) then
			if (nLevel > nLastLevel + 1) then
				szMsg	= szMsg .. "零";
			end
			szMsg	= szMsg .. string.format("%02d" .. tbTimeDesc[1], math.floor(nSec / nUnit));
			nSec	= math.mod(nSec, nUnit);
			nLastLevel	= nLevel;
		end
	end
	return szMsg;
end

-- 将游戏桢数转换为时间描述字符串
function Lib:FrameTimeDesc(nFrame)
	local nSec	= math.floor(nFrame / Env.GAME_FPS);
	return self:TimeDesc(nSec);
end

-- 将TabFile一次性载入，并返回一个数据table
--	数据以第一行为依据形成列名，返回值形如：
--	{
--		[nRow]	= {[szCol] = szValue, [szCol] = szValue, ...},
--		[nRow]	= {[szCol] = szValue, [szCol] = szValue, ...},
--		...
--	}
function Lib:LoadTabFile(szFileName, tbNumColName, bOutsidePackage, bReadOnly)
	if bReadOnly == nil then
	    bReadOnly = true
	end
	local tbData	= KLib.LoadTabFileEx(szFileName, bOutsidePackage or 0);
	if (not tbData) then	-- 未能读取到
		return;
	end
	tbNumColName	= tbNumColName or {};
	local tbColName	= tbData[1];
	tbData[1]	= nil;
	local tbRet	= {};
	for nRow, tbDataRow in pairs(tbData) do
		local tbRow	= {}
		tbRet[nRow - 1]	= tbRow;
		for nCol, szName in pairs(tbColName) do
			if (tbNumColName[szName]) then
				tbRow[szName]	= tonumber(tbDataRow[nCol]) or 0;
			else
				tbRow[szName]	= tbDataRow[nCol];
			end
		end
	end
    if bReadOnly then
	    tbRet = SetReadOnly(tbRet)
	end
	return tbRet;
end

function Lib:LoadTabFileEx(szFile, szType, szIndex, tbField, bOutsidePackage, bTransToUTF8, nBeginRow, bReadOnly)
	local tbTab = {}
	if bReadOnly == nil then
		bReadOnly = true
	end
	tbTab = LoadTabFileEx(szFile, szType, szIndex, tbField, bOutsidePackage or 0, bTransToUTF8 or 1, nBeginRow or 2)
	if bReadOnly then
		if (not tbTab) then
			LogErr("LoadTabFileEx cannot load file", szFile)
		end
		tbTab = SetReadOnly(tbTab)
	end
	return tbTab
end

-- 将IniFile一次性载入，并返回一个数据table
--	以[Section]为第一级table下标，Key为第二级table下标，形如：
--	{
--		[szSection]	= {[szKey] = szValue, [szKey] = szValue, ...},
--		[szSection]	= {[szKey] = szValue, [szKey] = szValue, ...},
--		...
--	}
function Lib:LoadIniFile(szFileName)
	return KLib.LoadIniFile(szFileName);
end

-- 随机打乱一个连续的Table
function Lib:SmashTable(tb)
	local nLen	= #tb;
	for n, value in pairs(tb) do
		local nRand = MathRandom(nLen);
		tb[n]		= tb[nRand];
		tb[nRand]	= value;
	end
end

-- 是否为空的table
function Lib:IsEmptyTB(tb)
    return _G.next( tb ) == nil;
end

-- 获得一个32位数中指定位段(0~31)所表示的整数
function Lib:LoadBits(nInt32, nBegin, nEnd)
	if (nBegin > nEnd) then
		local _ = nBegin;
		nBegin = nEnd;
		nEnd   = _;
	end
	if (nBegin < 0) or (nEnd >= 32) then
		return 0;
	end
	nInt32 = nInt32 % (2 ^ (nEnd + 1));
	nInt32 = nInt32 / (2 ^ nBegin);
	return math.floor(nInt32);
end

-- 设置一个32位数中的指定位段(0~31)为指定整数
function Lib:SetBits(nInt32, nBits, nBegin, nEnd)
	if (nBegin > nEnd) then
		local _ = nBegin;
		nBegin = nEnd;
		nEnd   = _;
	end
	nBits = nBits % (2 ^ (nEnd - nBegin + 1));
	nBits = nBits * (2 ^ nBegin);
	nInt32 = nInt32 % (2 ^ nBegin) + nInt32 - nInt32 % (2 ^ (nEnd + 1));
	nInt32 = nInt32 + nBits;
	return nInt32;
end

-- 获取bit值
function Lib:GetTableBit(tb, nPos)
	assert(nPos >= 0, "Lib:GetTableBit nPos = " .. nPos);

	local nIndex = math.floor(nPos / 32);
	local nRealPos = nPos % 32;

	if not tb or not tb[nIndex] then
		return 0;
	end

	return self:LoadBits(tb[nIndex], nRealPos, nRealPos);
end

-- 设置表内bit值
function Lib:SetTableBit(tb, nPos, nBit)
	assert(nPos >= 0, "Lib:GetTableBit nPos = " .. nPos);

	local nIndex = math.floor(nPos / 32);
	local nRealPos = nPos % 32;

	if not nBit or nBit ~= 0 then
		nBit = 1;
	end

	tb[nIndex] = tb[nIndex] or 0;
	tb[nIndex] = self:SetBits(tb[nIndex], nBit, nRealPos, nRealPos);
end

--从凌晨开始算 获得当天过了多少秒
function Lib:GetTodaySec(nTime)
    local nTimeNow = nTime or GetTime();
	if MODULE_GAMECLIENT then
		nTimeNow = nTimeNow +  GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end
    local tbTime = os.date("*t", nTimeNow);

    return tbTime.hour * 3600 + tbTime.min * 60 + tbTime.sec;
end

function Lib:GetTimeStrNew(nTimestamp)
	if MODULE_GAMECLIENT then
		nTimestamp = nTimestamp +  GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end
	return os.date("%Y%m%d%H%M%S", nTimestamp)
end

-- 20:00:00 20:15 解析当天的时间
function Lib:ParseTodayTime(szDateTime)
   local nHour, nMinute, nSecond = string.match(szDateTime, "(%d+):(%d+):(%d+)");
   if not nHour then
		nHour, nMinute = string.match(szDateTime, "(%d+):(%d+)");
   end

   nSecond = nSecond or 0;
   local nTime = nHour * 3600 + nMinute * 60 + nSecond;
   return nTime;
end

-- 获取时差（秒数）
function Lib:GetGMTSec()
	--由于越南1970年用的是旧的东8时区,1975.06.13及之后改为现在的东7时区,所以这里不能使用os.date("*t", 0)
	--取巧的方法是传入1979.12.30的时间来获取其时区值.
	local tbTime = os.date("*t", 10 * 3600 * 24 * 365 - (self.bIsDst and 3600 or 0));
	local nTimeSecDiff = 0
	if MODULE_GAMECLIENT then
		--由于os.date得到的时区取值范围是[0~24](东区是0~12，西区是昨天的13~24),而GetZoneTimeSecDiff()中的时区取值范围是[-12,12]，
		--这造成在西区的客户端最终得到的值会+24小时，这里需要做些判断和转化
		if tbTime.day ~= 30 then
			nTimeSecDiff = GetZoneTimeSecDiff() - (24 * 3600)
		else
			nTimeSecDiff = GetZoneTimeSecDiff()
		end
	end
	return (tbTime.hour * 3600 + tbTime.min * 60 + tbTime.sec) + nTimeSecDiff;
end

-- 根据秒数（UTC，GetTime()返回）计算当地时间今天已经过的秒数
function Lib:GetLocalDayTime(nUtcSec)
	local nLocalSec	= (nUtcSec or GetTime()) + self:GetGMTSec();
	return math.mod(nLocalSec, 3600 * 24);
end


-- 根据秒数（UTC，GetTime()返回）计算当地时间今天已经过的小时
function Lib:GetLocalDayHour(nUtcSec)
	local nLocalSec	= (nUtcSec or GetTime()) + self:GetGMTSec();
	local nDaySec = math.mod(nLocalSec, 3600 * 24);
	return math.floor(nDaySec / 3600);
end

-- 根据秒数（UTC，GetTime()返回）计算当地时间今天已经过的小时,和分钟
function Lib:GetLocalDayHourAndMinute(nUtcSec)
	local nLocalSec	= (nUtcSec or GetTime()) + self:GetGMTSec();
	local nDaySec = math.mod(nLocalSec, 3600 * 24);
	local nMinSec = math.mod(nDaySec, 3600)
	return math.floor(nDaySec / 3600), math.floor(nMinSec / 60)
end

-- 根据秒数（UTC，GetTime()返回）计算当地天数
--	1970年1月1日 返回0
--	1970年1月2日 返回1
--	1970年1月3日 返回2
--	……依此类推
function Lib:GetLocalDay(nUtcSec)
	local nLocalSec	= (nUtcSec or GetTime()) + self:GetGMTSec();
	return math.floor(nLocalSec / (3600 * 24));
end

-- 根据秒数（UTC，GetTime()返回）计算当地周数
--	1970年1月1日 星期四 返回0
--	1970年1月4日 星期日 返回0
--	1970年1月5日 星期一 返回1
--	……依此类推
function Lib:GetLocalWeek(nUtcSec)
	local nLocalDay	= self:GetLocalDay(nUtcSec);
	return math.floor((nLocalDay + 3) / 7);
end

-- 周一到周日 返回 1~7
function Lib:GetLocalWeekDay(nUtcSec)
	local nLocalDay	= self:GetLocalDay(nUtcSec);
	return (nLocalDay + 3) % 7 + 1;
end

-- 获取第nWeek周(本地周数), 星期nDay(1-7), nHour:nMin:nSec的时间
function Lib:GetTimeByWeek(nWeek, nDay, nHour, nMin, nSec)
    if not nWeek or not nDay
    or (nWeek <= 0) then        -- 第0周就不处理了。。。
        return nil;
    end
    nDay = nDay + (nWeek - 1) * 7 + 4;
    return os.time{year = 1970, month = 1, day = nDay,
                   hour = nHour, min = nMin, sec = nSec} + (self.bIsDst and 3600 or 0)
end

function Lib:GetTimeByDay(nDay, nHour, nMin, nSec)
    if not nDay then
        return nil;
    end
    return os.time{year = 1970, month = 1, day = nDay + 1,
                   hour = nHour, min = nMin, sec = nSec} + (self.bIsDst and 3600 or 0)
end

-- 返回时间戳对应的人类可阅读的数字（如：20160222）
function Lib:GetTimeNum(timestamp)
	timestamp = timestamp or GetTime()
	if MODULE_GAMECLIENT then
		timestamp = timestamp + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end
	local tbTime = os.date("*t", timestamp)
	return tbTime.year*10000 + tbTime.month*100 + tbTime.day
end

-- 返回时间戳对应的人类可阅读的数字（如：20210825105500）
function Lib:GetTimeNum2(bUTC, timestamp)
	timestamp = timestamp or GetTime()
	if MODULE_GAMECLIENT then
		timestamp = timestamp + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end
	local tbTime = (bUTC and {os.date("!*t", timestamp)} or {os.date("*t", timestamp)})[1]
	return tbTime.year*10000000000 + tbTime.month*100000000 + tbTime.day*1000000 + tbTime.hour*10000 + tbTime.min*100 + tbTime.sec
end

-- 返回2016-03-22
function Lib:GetTimeStr(nTimestamp)
	nTimestamp = nTimestamp or GetTime()

	if MODULE_GAMECLIENT then
		nTimestamp = nTimestamp + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end
	local tbTime = os.date("*t", nTimestamp)
	return string.format("%d-%.2d-%.2d", tbTime.year, tbTime.month, tbTime.day)
end

-- 返回03-22 16:33
function Lib:GetTimeStr2(nTimestamp)
	nTimestamp = nTimestamp or GetTime()
	if MODULE_GAMECLIENT then
		nTimestamp = nTimestamp + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end
	local tbTime = os.date("*t", nTimestamp)
	return string.format("%.2d-%.2d %.2d:%.2d", tbTime.month, tbTime.day, tbTime.hour, tbTime.min)
end

-- 返回2016-03-22 16:33
function Lib:GetTimeStr3(nTimestamp)
	nTimestamp = nTimestamp or GetTime()
	if MODULE_GAMECLIENT then
		nTimestamp = nTimestamp + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end

	local tbTime = os.date("*t", nTimestamp)
	return string.format("%d-%.2d-%.2d %.2d:%.2d", tbTime.year, tbTime.month, tbTime.day, tbTime.hour, tbTime.min)
end

-- 返回2016-03-22 16:33:30
function Lib:GetTimeStr4(nTimestamp)
	nTimestamp = nTimestamp or GetTime()
	if MODULE_GAMECLIENT then
		nTimestamp = nTimestamp + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end

	local tbTime = os.date("*t", nTimestamp)
	return string.format("%d-%.2d-%.2d %.2d:%.2d:%.2d", tbTime.year, tbTime.month, tbTime.day, tbTime.hour, tbTime.min, tbTime.sec)
end

-- 根据秒数（UTC，GetTime()返回）计算当地月数
--	1970年1月 返回0
--	1970年2月 返回1
--	1970年3月 返回2
--	……依此类推
function Lib:GetLocalMonth(nUtcSec)
	local nTimestamp = 0 ;
	nTimestamp = nUtcSec or GetTime();

	if MODULE_GAMECLIENT then
		nTimestamp = nTimestamp + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end

	local tbTime 	= os.date("*t", nTimestamp);
	return (tbTime.year - 1970) * 12 + tbTime.month - 1;
end

-- 根据秒数（UTC，GetTime()返回）计算当前是每月的 第几天
function Lib:GetLocalMonthDay(nUtcSec)
	local nTimestamp = 0 ;
	nTimestamp = nUtcSec or GetTime();

	if MODULE_GAMECLIENT then
		nTimestamp = nTimestamp + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end

	local tbTime 	= os.date("*t", nTimestamp);
	return tbTime.day
end

--获得当月天数
function Lib:GetThisMonthTotalDay()
	local timesec = GetTime()
	if MODULE_GAMECLIENT then
		timesec = timesec + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end
	local year,month = os.date("%Y", timesec), os.date("%m", timesec)+1 -- 正常是获取服务器给的时间来算
	local dayAmount = os.date("%d", os.time({year=year, month=month, day=0}) + (self.bIsDst and 3600 or 0)) -- 获取当月天数
	dayAmount = tonumber(dayAmount)

	if not dayAmount then
		return 30
	end

	if dayAmount < 28 then
		dayAmount = 28
	end

	if dayAmount > 31 then
		dayAmount = 31
	end
	return dayAmount
end

--返回固定日期的秒数
--nDate格式如(2008-6-25 00:00:00):20080625 ; 2008062500; 200806250000 ; 20080625000000
function Lib:GetDate2Time(nDate)
	local nDate = tonumber(nDate);
	if nDate == nil then
		return
	end
	local nSecd = 0;
	local nMin 	= 0;
	local nHour	= 0;
	local nDay 	= 0;
	local nMon 	= 0;
	local nYear = 0;
	if string.len(nDate) == 8 then
		 nDay = math.mod(nDate, 100);
		 nMon = math.mod(math.floor(nDate/100), 100);
		 nYear = math.mod(math.floor(nDate/10000),10000);
	elseif string.len(nDate) == 10 then
		 nHour = math.mod(nDate, 100);
		 nDay = math.mod(math.floor(nDate/100), 100);
		 nMon = math.mod(math.floor(nDate/10000),100);
		 nYear = math.mod(math.floor(nDate/1000000),10000);
	elseif string.len(nDate) == 12 then
		 nMin = math.mod(nDate, 100);
		 nHour= math.mod(math.floor(nDate/100), 100);
		 nDay = math.mod(math.floor(nDate/10000),100);
		 nMon = math.mod(math.floor(nDate/1000000),100);
		 nYear = math.mod(math.floor(nDate/100000000),10000);
	elseif string.len(nDate) == 14 then
		 nSecd = math.mod(nDate, 100);
		 nMin = math.mod(math.floor(nDate/100), 100);
		 nHour= math.mod(math.floor(nDate/10000), 100);
		 nDay = math.mod(math.floor(nDate/1000000),100);
		 nMon = math.mod(math.floor(nDate/100000000),100);
		 nYear = math.mod(math.floor(nDate/10000000000),10000);
	else
		return 0;
	end
	local tbData = {year=nYear, month=nMon, day=nDay, hour=nHour, min=nMin, sec=nSecd};
	local nSec = Lib:GetSecFromNowData(tbData)
	return nSec;
end

function Lib:GetSecFromNowData(tbData)
	local nSecTime = os.time(tbData) + (self.bIsDst and 3600 or 0);
	return nSecTime;
end

--时间显示转换:如1030转成10:30 ; 0转换成0:00
function Lib:HourMinNumber2TimeDesc(nTime)
	local nMin = math.mod(nTime, 100);
	local nHour = math.floor(nTime/ 100);
	local szMin = nMin;
	if nMin < 10 then
		szMin = "0" .. nMin;
	end
	local szTime = nHour .. ":" .. szMin;
	return szTime
end

-- 20220330122443 -> 1648614283
function Lib:ParseNumbericDateToTime(szDateTime)
	if string.len(szDateTime) ~= 14 then
		LogErr("Lib:ParseNumbericDateToTimem format error! szDateTime = ", szDateTime)
		return
	end
	local nTmp = tonumber(szDateTime)
	if not nTmp then
		LogErr("Lib:ParseNumbericDateToTimem format error! szDateTime = ", szDateTime)
		return
	end
	local nYear		= string.sub(szDateTime, 1, 4)
	local nMonth	= string.sub(szDateTime, 5, 6)
	local nDay		= string.sub(szDateTime, 7, 8)
	local nHour		= string.sub(szDateTime, 9, 10)
	local nMinute	= string.sub(szDateTime, 11, 12)
	local nSecond	= string.sub(szDateTime, 13, 14)
	if not nYear or not nMonth or not nDay or not nHour or not nMinute or not nSecond then
		LogErr("Lib:ParseNumbericDateToTimem format error! szDateTime = ", szDateTime)
		return
	end
	local nTime = os.time({year = nYear, month = nMonth, day = nDay, hour = nHour, min = nMinute, sec = nSecond})
	if MODULE_GAMECLIENT then
		nTime = nTime - GetZoneTimeSecDiff() + (self.bIsDst and 3600 or 0)
	end
	return nTime
end

-- 支持
--		2012-09-28 10:50:51
--		2012.09.28 10:50:51
--		2012-09-28
--		2012.09.28
function Lib:ParseDateTime(szDateTime)
	if not szDateTime then
		return
	end
	-- 2012/09/28 10:50:51
	local year, month, day, hour, minute, second = string.match(szDateTime, "(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)");

	-- 2012-09-28 10:50:51
	if not year then
		year, month, day, hour, minute, second = string.match(szDateTime, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)");
	end

	-- 2012.09.28 10:50:51
	if not year then
		year, month, day, hour, minute, second = string.match(szDateTime, "(%d+).(%d+).(%d+) (%d+):(%d+):(%d+)");
	end

	if not year then
		year, month, day = string.match(szDateTime, "(%d+)/(%d+)/(%d+)");
		hour, minute, second = 0, 0, 0;
	end

	if not year then
		year, month, day = string.match(szDateTime, "(%d+)-(%d+)-(%d+)");
		hour, minute, second = 0, 0, 0;
	end

	if not year then
		Log("Lib:ParseDateTime 时间字符串格式不合规范" .. szDateTime, debug.traceback());
		return;
	end
	
	local nTime = os.time({year = year, month = month, day = day, hour = hour, min = minute, sec = second})
	if MODULE_GAMECLIENT then
		nTime = nTime - GetZoneTimeSecDiff() + (self.bIsDst and 3600 or 0)
	end
	return nTime
end

--把整形的IP地址转成字符串表示(xxx.xxx.xxx.xxx)
function Lib:IntIpToStrIp(nIp)
	--local nIp = tonumber(nIp);
	if nIp == nil then
		return "";
	end
	local tbIp = {};
	tbIp[1] = self:LoadBits(nIp, 0,  7);
	tbIp[2] = self:LoadBits(nIp, 8, 15);
	tbIp[3] = self:LoadBits(nIp, 16, 23);
	tbIp[4] = self:LoadBits(nIp, 24, 31);
	local szIp = string.format("%d.%d.%d.%d", tbIp[1], tbIp[2], tbIp[3], tbIp[4]);
	return szIp;
end

function Lib:IsInteger(val)
	if (not val or type(val) ~= "number") then
		return false;
	elseif (math.floor(val) == val) then
		return true;
	end
	return false;
end

function Lib:GetUft8Chars(s)
	local nTotalLen = string.len(s);
	local nCurIdx = 1;
	local tbResult = {};
	while nCurIdx <= nTotalLen do
		local c = string.byte(s, nCurIdx);
		if c > 0 and c <= 127 then
			table.insert(tbResult, string.sub(s, nCurIdx, nCurIdx));
			nCurIdx = nCurIdx + 1;
		elseif c >= 194 and c <= 223 then
			table.insert(tbResult, string.sub(s, nCurIdx, nCurIdx + 1));
			nCurIdx = nCurIdx + 2;
		elseif c >= 224 and c <= 239 then
			table.insert(tbResult, string.sub(s, nCurIdx, nCurIdx + 2));
			nCurIdx = nCurIdx + 3;
		elseif c >= 240 and c <= 244 then
			table.insert(tbResult, string.sub(s, nCurIdx, nCurIdx + 3));
			nCurIdx = nCurIdx + 4;
		else
			-- 语音最后会多个\0
			break
		end
	end

	return tbResult;
end

--判断是否全是汉字
function Lib:IsAllChinese(str)
    if TRANSLATE_LANGUAGE == "vet" then
        return true -- TODO: 越南文暂时不限制
    end
    local nLen = #str
    if nLen > 0 and nLen%3 == 0 then
        for i = 1, nLen, 3 do
            local tmp1 = string.byte(str, i)
            local tmp2 = string.byte(str, i+1)
            local tmp3 = string.byte(str, i+2)
            if tmp1 < 228 or tmp1 > 233 then
                return false
            elseif tmp1 == 228 then
                if tmp2 < 184 then
                    return false
                elseif tmp2 == 184 then
                    if tmp3 < 128 then
                        return false
                    end
                end
            elseif tmp1 == 233 then
                if tmp2 > 191 then
                    return false
                elseif tmp2 == 191 then
                    if tmp3 >191 then
                        return false
                    end
                end
            end

        end
        return true
    end
    return false
end

function Lib:Utf8Len(s)
	if s and type(s) == "string" then
		return KLib.GetUtf8Len(s);
	else
		return 0;
	end
end

function Lib:CutUtf8(s, nLen)
	return KLib.CutUtf8(s, nLen);
end

function Lib:InitTable(tb, ...)
	local tbIdx = {...};
	for _, key in ipairs(tbIdx) do
		tb[key] = tb[key] or {};
		tb = tb[key];
	end

	return tb;
end

--获得当前最大的时间轴，在Setting/timeframe中
function Lib:GetMaxTimeFrame(tbTimeFrame)
    local szCurTimeFrame 	= "";
    local nCurTimeFrameTime = -1;

    for szTimeFrame, _ in pairs(tbTimeFrame) do
        if szTimeFrame ~= "-1" and GetTimeFrameState(szTimeFrame) == 1 then
            local nOpenTime = Lib:CalcTimeFrameOpenTime(szTimeFrame);
            if nOpenTime > nCurTimeFrameTime then
                nCurTimeFrameTime = nOpenTime;
                szCurTimeFrame = szTimeFrame;
            end
        end
    end

    return szCurTimeFrame;
end

--获得当前最大的时间轴，在Setting/timeframe中
function Lib:GetMaxTimeFrameByTargetTime(tbTimeFrame, nTargetTime)
    local szMaxTimeFrame 	= "";
    local nMaxTimeFrameTime = -1;

    for szTimeFrame, _ in pairs(tbTimeFrame) do
        if szTimeFrame ~= "-1" then
            local nOpenTime = Lib:CalcTimeFrameOpenTime(szTimeFrame);
            if nTargetTime > nOpenTime and nOpenTime > nMaxTimeFrameTime then
                nMaxTimeFrameTime = nOpenTime;
                szMaxTimeFrame = szTimeFrame;
            end
        end
    end

    return szMaxTimeFrame;
end

function Lib:GetCountInTable(tbItems, fnEqual, param)
	local nCount = 0;
	for _, tbItem in pairs(tbItems) do
		if fnEqual(tbItem, param) then
			nCount = nCount + 1;
		end
	end

	return nCount;
end

function Lib:GetDistsSquare(nX1, nY1, nX2, nY2)
    local fOfX = nX2 - nX1
    local fOfY = nY2 - nY1
    return fOfX * fOfX + fOfY * fOfY
end

function Lib:GetDistance(nX1, nY1, nX2, nY2)
    local fDist = Lib:GetDistsSquare(nX1, nY1, nX2, nY2)
    return math.sqrt(fDist)
end

function Lib:GetServerOpenDay()
	local nCreateTime = GetServerCreateTime();
	local nToday = Lib:GetLocalDay();
	return nToday - Lib:GetLocalDay(nCreateTime) + 1;
end

-- 以早上4点钟为跨天时间计算开服日期
function Lib:GetServerOpenDay_4AM()
	local nCreateTime = GetServerCreateTime() - 3600 * 4
	local nCurTime = GetTime() - 3600 * 4
	local nToday = Lib:GetLocalDay(nCurTime);
	return nToday - Lib:GetLocalDay(nCreateTime) + 1;
end

-- 以早上4点钟为跨天时间计算开服日期(创建服务器时间不计算4点跨天，跟活动日历计算方式保持一致)
function Lib:GetServerOpenDay_Calendar()
	local nCreateTime = GetServerCreateTime()
	local nCurTime = GetTime() - 3600 * 4
	local nToday = Lib:GetLocalDay(nCurTime);
	return nToday - Lib:GetLocalDay(nCreateTime) + 1;
end

--功能：判断两个时间是否不在同一天
--nOffset:时间偏移(单位为s)，比如以4点为新的一天标准，那么该值为 4 * 60 * 60
--nTime1:需要比较的第一个时间(s)
--nTime2:需要比较的第二个时间(s)，不传便取当前时间
--返回值：true：两个时间不在同一天，false：两个时间在同一天
function Lib:IsDiffDay(nOffset, nTime1, nTime2)
	nTime2 = nTime2 or GetTime();
	local nDay1 = self:GetLocalDay(nTime1 - nOffset);
	local nDay2 = self:GetLocalDay(nTime2 - nOffset);
	return nDay1 ~= nDay2;
end

function Lib:IsSameDay(nOffset, nTime1, nTime2)
	return not self:IsDiffDay(nOffset, nTime1, nTime2)
end

--功能：判断两个时间是否不在同一周
--nOffset:时间偏移(单位为s)，比如以4点为新的一周标准，那么该值为 4 * 60 * 60
--nTime1:需要比较的第一个时间(s)
--nTime2:需要比较的第二个时间(s)，不传便取当前时间
--返回值：true：两个时间不在同一周，false：两个时间在同一周
function Lib:IsDiffWeek(nOffset, nTime1, nTime2)
	nTime2 = nTime2 or GetTime()
	local nWeek1 = self:GetLocalWeek(nTime1 - nOffset)
	local nWeek2 = self:GetLocalWeek(nTime2 - nOffset)
	return nWeek1 ~= nWeek2
end

function Lib:IsSameWeek(nOffset, nTime1, nTime2)
	return not self:IsDiffWeek(nOffset, nTime1, nTime2)
end

function Lib:SecondsToDays(nSeconds)
	return math.floor(nSeconds/(24*3600))
end

-- 功能:	把字符串扩展为长度为nLen,左对齐, 其他地方用空格补齐
-- 参数:	szStr	需要被扩展的字符串
-- 参数:	nLen	被扩展成的长度
function Lib:StrFillL(szStr, nLen, szFilledChar)
	szStr				= tostring(szStr);
	szFilledChar		= szFilledChar or " ";
	local nRestLen		= nLen - string.len(szStr);								-- 剩余长度
	local nNeedCharNum	= math.floor(nRestLen / string.len(szFilledChar));	-- 需要的填充字符的数量

	szStr = szStr..string.rep(szFilledChar, nNeedCharNum);					-- 补齐
	return szStr;
end


-- 功能:	把字符串扩展为长度为nLen,右对齐, 其他地方用空格补齐
-- 参数:	szStr	需要被扩展的字符串
-- 参数:	nLen	被扩展成的长度
function Lib:StrFillR(szStr, nLen, szFilledChar)
	szStr				= tostring(szStr);
	szFilledChar		= szFilledChar or " ";
	local nRestLen		= nLen - string.len(szStr);								-- 剩余长度
	local nNeedCharNum	= math.floor(nRestLen / string.len(szFilledChar));	-- 需要的填充字符的数量

	szStr = string.rep(szFilledChar, nNeedCharNum).. szStr;					-- 补齐
	return szStr;
end

-- 功能:	把字符串扩展为长度为nLen,居中对齐, 其他地方以空格补齐
-- 参数:	szStr	需要被扩展的字符串
-- 参数:	nLen	被扩展成的长度
function Lib:StrFillC(szStr, nLen, szFilledChar)
	szStr				= tostring(szStr);
	szFilledChar		= szFilledChar or " ";
	local nRestLen		= nLen - string.len(szStr);								-- 剩余长度
	local nNeedCharNum	= math.floor(nRestLen / string.len(szFilledChar));	-- 需要的填充字符的数量
	local nLeftCharNum	= math.floor(nNeedCharNum / 2);							-- 左边需要的填充字符的数量
	local nRightCharNum	= nNeedCharNum - nLeftCharNum;							-- 右边需要的填充字符的数量

	szStr = string.rep(szFilledChar, nLeftCharNum)
			..szStr..string.rep(szFilledChar, nRightCharNum);				-- 补齐
	return szStr;
end

-- 功能:	判断文件是否存在
-- 参数:	strFilePath	文件路径
function Lib:IsFileExsit(strFilePath)
	local file, err = io.open(strFilePath, "rb");
	if  not file then
		return false
	end

	file:close();
	return true
end

-- 功能:	读取一个二进制文件
-- 参数:	strFilePath	文件路径
function Lib:ReadFileBinary(strFilePath)
	local file, err = io.open(strFilePath, "rb");
	if  not file then
		return nil
	end

	local len = file:seek("end")

	file:seek("set")

	local data = file:read("*all");

	file:close();
	return data, len
end

-- 功能:	写二进制文件
-- 参数:	strFilePath	文件路径
-- 参数:	szData	二进制数据
function Lib:WriteFileBinary(strFilePath, szData)
	local file, err = io.open(strFilePath, "wb");
	if  not file then
		return false
	end

	file:write(szData);

	file:close();
	return true
end

-- 获取一个table占用内存大小
function Lib:GetTableSize(tbRoot)
	local tbChecked = {};
	local function fnGetSize(tb)
		local nSize = debug.gettablesize(tb);
		for _, value in pairs(tb) do
			if type(value) == "table" and not tbChecked[value] then
				tbChecked[value] = true;
				nSize = nSize + fnGetSize(value);
			end
		end
		return nSize;
	end
	local nSize = fnGetSize(tbRoot);
	tbChecked = nil;
	return nSize;
end

function Lib:DecodeJson(szJson)
	return cjson.decode(szJson);
end

function Lib:EncodeJson(value)
	return cjson.encode(value);
end

--Unity角度计算得到 我们引擎的角度
--0~360 C++不支持 负数角度
function Lib:FloatDirToInt( fAngle )
	-- return -nDir * 64 / 360.0 + 64
	local angle = fAngle
	if fAngle>=360 then
		angle = fAngle-360
	end
	angle = (450-angle)%360
	local nDir =  angle*Env.LOGIC_MAX_DIR/360
	return nDir
end

--C++ 角度转化为Unity角度
function Lib:NDirToFloatDir( nDir )
	-- local nDir2 = nDir * 360 / 64.0
 --    local nRealDir = -nDir2
	-- return nRealDir
	local rotateAngle = nDir/Env.LOGIC_MAX_DIR*360
	rotateAngle = (450-rotateAngle)%360
	return rotateAngle
end


--剑三角度制 Unity角度转换为Dir
function Lib:FloatAngleToDir( fAngle )
	local angle = fAngle
	if fAngle>=360 then
		angle = fAngle-360
	end
	angle = (450-angle)%360
	local nDir =  angle*Env.LOGIC_MAX_DIR/360
	return nDir
end

--剑三角度制 Dir转换为Unity角度
function Lib:DirToFloatAngle( nDir )
	local rotateAngle = nDir/Env.LOGIC_MAX_DIR*360
	rotateAngle = (450-rotateAngle)%360
	return rotateAngle
end

--

--确保角度 > 0
function Lib:NormalizeDir( nDir )
	nDir = nDir % Env.LOGIC_MAX_DIR
	if nDir < 0 then
		nDir = nDir + Env.LOGIC_MAX_DIR
	end
	return nDir
end

--相对于Master的tbPos  朝向nDir 偏移位置 tbOffPos
function Lib:CalRotOffPos( tbPos, tbOffPos, nDir )
	--Log("CalRotOffPos", tostring(tbPos), tostring(tbOffPos), tostring(nDir))
	local nDir2 = 450-(nDir * 360 / Env.LOGIC_MAX_DIR)
    local nRealDir = -math.rad(nDir2)

    --Lib:Tree(tbPos)
    --2D
    --pos + rot*offPos
    local cosTheta = math.cos(nRealDir)
    local sinTheta = math.sin(nRealDir)
    --Log("CostValue", cosTheta, sinTheta)
    local tbRelativePos = {tbOffPos[1] * 512/100, tbOffPos[2] * 512/100}

    local rotX = cosTheta * tbRelativePos[1] - sinTheta * tbRelativePos[2]
    local rotY = sinTheta * tbRelativePos[1] + cosTheta * tbRelativePos[2]
    --Log("RotValue", rotX, rotY)
    local newPosX, newPosY = tbPos[1] + rotX, tbPos[2] + rotY

    newPosX = math.floor(newPosX)
    newPosY = math.floor(newPosY)
    return newPosX, newPosY
end

--根据相对位置 计算C++引擎的角度  先计算Unity中的Y轴角度
function Lib:CalDirByPos( dx, dy )
	local nTheta = math.atan2(dx, dy)
	nTheta = -math.deg(nTheta)
	if nTheta < 0 then
		nTheta = nTheta + 360
	end
	return Lib:FloatDirToInt(nTheta)
end

--获取当前时间
function Lib:GetCurTimeStr()
	local nTimeNow = nTime or GetTime();
    if MODULE_GAMECLIENT then
		nTimeNow = nTimeNow +  GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end
	local strDate = os.date("%Y-%m-%d %H:%M:%S", nTimeNow);
	return strDate;
end

-- 根据秒数和格式字符串，返回时间格式
function Lib:OSDate(szFomat, nTime)
	local mRelTime = nTime or GetTime()
	if MODULE_GAMECLIENT then
		mRelTime = mRelTime + GetZoneTimeSecDiff() - (self.bIsDst and 3600 or 0)
	end
	return os.date(szFomat, mRelTime)
end

function Lib:StrStartWith( szStr, szStart )
	return (string.sub(szStr, 1, string.len(szStart)) == szStart)
end


function Lib:RandTable( tbTable )
    local count = #tbTable
    local v = MathRandom(count)
    return tbTable[v]
end

-- nNum : cm
function Lib:Map2Logic(nNum)
    return nNum * 8 -- (5.12 * 100 / 64)
end

-- nNum : 逻辑长度
function Lib:Logic2Map(nNum)
    return nNum / 8 --(5.12 * 100 / 64)
end

function Lib:DefaultTable( tab, ... )
	local curTab = tab
	for i, v in ipairs({...}) do
		curTab[v] = curTab[v] or {}
		curTab = curTab[v]
	end
	return curTab
end

function Lib:GetTableDeepKey( tab, ... )
	local curTab = tab
	for i, v in ipairs({...}) do
		local ret = curTab[v]
		if ret ~= nil then
			curTab = ret
		else
			return nil
		end
	end
	return curTab
end

--设置深度Table
function Lib:SetTableDeepKey( tab, ... )
	local curTab = tab
	local pack = Lib:TablePack(...)
	for i=1, pack.n-1, 1 do
		local v = pack[i]
		if i < (pack.n-1) then
			if curTab[v] == nil then
				curTab[v] = {}
			end
			curTab = curTab[v]
		else
			curTab[v] = pack[i+1]
		end
	end
end

--数组转化为深度Dict
--没有重复的Key guanjia1->107->108
function Lib:ListToDict( tab )
	local res = {}
	for k, v in pairs(tab) do
		self:SetTableDeepKey(res, unpack(v))
	end
	return res
end

function Lib:ListToSet( tab )
	local res = {}
	for k, v in pairs(tab) do
		res[v] = true
	end
	return res
end

function Lib:GetAllTableKeys(tab)
	local tbAllKeys = {}
	for k, _ in pairs(tab) do
		table.insert(tbAllKeys, k)
	end
	return tbAllKeys
end

function Lib:GetPronounByPlayer(pPlayer)
	return Player:GetPlayerSex(pPlayer) == 0 and "他" or "她"
end

function Lib:Is_include(value, tab)
    for k,v in ipairs(tab) do
      if v == value then
          return true
      end
    end
    return false
end

function Lib:DebugAssert(bCondition)
	if not bCondition then
		LogErr("Lib:DebugAssert Fail: ", debug.traceback())
		DebugAssert()
	end
end

--四舍五入方法
function Lib:MathRound(nValue)
    local nResult = tonumber(nValue) or 0
    return math.floor(nResult + 0.5)
end

function Lib:PairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, f)
    local i = 0 -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function Lib:GetTableMaxKey(tbData)
	if not tbData then
		return 0
	end
	local nResult = 0
	for nKey, _ in pairs(tbData) do
		nResult = math.max(nResult, nKey)
	end
	return nResult
end

-- 获取table最外层key数量
function Lib:GetTableLength(tbVar)
	if not tbVar then
		return 0
	end
	local nRet = 0
	for _, objVal in pairs(tbVar) do
		nRet = nRet + 1
	end
	return nRet
end

Lib.bLog = true;
function Lib:GetLogSwitch()
	return self.bLog;
end
function Lib:SetLogSwitch(bLog)
	if nil == bLog then
		bLog = false;
	elseif 0 == bLog then
		bLog = false;
	end
	self.bLog = bLog;
end
local function _LogFormat(...)
	local tbParams = {...};
	local szFormat = tbParams[1];
	table.remove(tbParams, 1);
	return string.format(szFormat, unpack(tbParams));
end
function Lib:LogFormat(...)
	if self.bLog then
		Log(_LogFormat(...));
	end
end
function Lib:LogErrFormat(...)
	if self.bLog then
		LogErr(_LogFormat(...));
	end
end

--只能在客户端使用
function Lib:ClearPlayerScriptTable(pPlayer, szKey)
	if not pPlayer then
		return
	end
	local tbTable= pPlayer.GetScriptTable(szKey)
	if not tbTable then
		return
	end
	for k, _ in pairs(tbTable) do
		tbTable[k] = nil;
	end
	Log("Lib:ClearPlayerScriptTable", pPlayer.dwID, szKey)
end

function Lib:PrintLuaTable(tbSomething, szTbName, szDeepSign)
    if not szDeepSign or szDeepSign == "" then
        szDeepSign = ""
        print(string.format("------------- start print table[%s]-------------", szTbName or "empty_table"))
        print(string.format("%s{", szDeepSign))
    end
    local oldDeepSign = szDeepSign
    szDeepSign = szDeepSign .. "    "
    if tbSomething then
        if type(tbSomething) == "table" then
            for key, value in pairs(tbSomething) do
                local szLine = ""
                local szFormat = ""
                if type(key) == "string" then
                    szFormat = "%s[\"%s\"]"
                elseif type(key) == "number" then
                    szFormat = "%s[%d]"
                end

                szLine = string.format(szFormat, szDeepSign, key)
                if not value then
                    szLine = szLine .. " = nil,"
                elseif type(value) == "number" then
                    szLine = szLine .. string.format(" = %d,", value)
                elseif type(value) == "string" then
                    szLine = szLine .. string.format(" = \"%s\",", value)
                elseif type(value) == "boolean" then
                    if value == true then
                        szLine = szLine .. " = true,"
                    else
                        szLine = szLine .. " = false,"
                    end
                end


                if type(value) == "table" then
                    print(szLine.." = {")
                    self:PrintLuaTable(value, "subTb", szDeepSign)
                else
                    print(szLine)
                end
            end
        end
    else
        print("nil")
    end
    print(string.format("%s},", oldDeepSign))
    if not oldDeepSign or oldDeepSign == "" then
        print("------------------ end ---------------------")
    end
end

-- 把16进制颜色字符串转换成r, g, b
-- 例如：szColor = "98D2BA"， 返回 r = 152, g = 210, b = 186
function Lib:ParseColorStrToRGB(szColor)
	if (not szColor or string.len(szColor) ~= 6) then
		return 0, 0, 0
	end
	local nR = string.sub(szColor, 1, 2)
	local nG = string.sub(szColor, 3, 4)
	local nB = string.sub(szColor, 5, 6)
	nR = tonumber(nR, 16)
	nG = tonumber(nG, 16)
	nB = tonumber(nB, 16)
	return nR, nG, nB
end

function Lib:DoString(szExcuteCmd)
	local func, err = loadstring(szExcuteCmd)
	if err then
		LogErr("Error in processing results: " .. err)
		return false
	end
	if not func then
		LogErr("Error in processing not fun!")
		return false
	end
	local ok, fired = pcall(func)
	if not ok then
		LogErr("Lib:DoString Err:", fired)
	end
	return ok
end

function Lib:JoinNumbers(tbNumberList, szSpacer)
	szSpacer = szSpacer or ","
	if not tbNumberList then
		return ""
	end
	if #tbNumberList <= 0 then
		return ""
	end
	local szResult = ""
	for nIndex, nVar in ipairs(tbNumberList) do
		if nIndex == 1 then
			szResult = tostring(nVar or 0)
		else
			szResult = string.format("%s%s%s", szResult, szSpacer, nVar or 0)
		end
	end
	return szResult
end

-- 把table的第一层key和value拼接成字符串返回
function Lib:JoinTableRoot(tbTable)
	if not tbTable then
		return ""
	end
	if not next(tbTable) then
		return ""
	end
	local szResult = ""
	for k, v in pairs(tbTable) do
		if szResult == "" then
			szResult = string.format("%s=%s", tostring(k), tostring(v))
		else
			szResult = string.format("%s,%s=%s", szResult, tostring(k), tostring(v))
		end
	end
	return szResult
end

function Lib:MBILogFormatAndCheck(nLogReason)
	if (not nLogReason) or nLogReason == 0 then
		LogErr(string.format("Lib:MBILogCheck (not nLogReason) or nLogReason == 0!! nLogReason:%d, trace:%s", nLogReason or -1, debug.traceback()))
		return
	end

	local szMainReason = Env.tbLogWayMainWays[nLogReason]
	if not szMainReason then
		LogErr(string.format("Lib:MBILogCheck not Env.tbLogWayMainWays[nLogReason]!! nLogReason:%d, trace:%s", nLogReason or -1, debug.traceback()))
		return
	end

	local szSubReason = Env.tbLogWaySubWays[nLogReason]
	if not szSubReason then
		LogErr(string.format("Lib:MBILogCheck not Env.tbLogWaySubWays[nLogReason]!! nLogReason:%d, trace:%s", nLogReason or -1, debug.traceback()))
		return
	end

	return szMainReason, szSubReason
end

--数据埋点
function Lib:MBIPLog(dwPlayerId, nLogReason, ...)
	local szMBIMainEventMsg, szMBISubEventMsg = Lib:MBILogFormatAndCheck(nLogReason)
	if not szMBISubEventMsg then
		return
	end
	MBI_ReportPlayerEvent(dwPlayerId, szMBIMainEventMsg, szMBISubEventMsg, ...)
	if WINDOWS then
		Log("MBIPLog", dwPlayerId, szMBIMainEventMsg, szMBISubEventMsg, ...)
	end
end

function Lib:MBIGLog(nLogReason, ...)
	local szMBIMainEventMsg, szMBISubEventMsg = Lib:MBILogFormatAndCheck(nLogReason)
	if not szMBISubEventMsg then
		return
	end
	MBI_ReportGlobalEvent(szMBIMainEventMsg, szMBISubEventMsg, ...)
	if WINDOWS then
		Log("MBIGLog", szMBIMainEventMsg, szMBISubEventMsg, ...)
	end
end
function Lib:MBIScanGLog(szEventId, tbData)
	if not szEventId then
		return
	end
	MBI_ReportScanGlobalEvent(szEventId, tbData)
	-- Log("MBI_ReportScanGlobalEvent", szEventId)
end

function Lib:IsStrSameIgnoreCase(str1, str2)
	if KLib.ToLowerSameChar(str1) == KLib.ToLowerSameChar(str2) then
		return true
	end
	return false
end

--将字符串转小写，包括了英文字母和越南文的大小写，对应关系见SameChar.txt
function Lib:StringToLowerSameChar(str)
	return KLib.ToLowerSameChar(str)
end

function Lib:IsUnityObjNil(uObj)
	return uObj == nil or uObj:Equals(nil)
end

-- 替代C++提供的 CalcTimeFrameOpenTime 方法
-- 计算当天0点的时间时，越南时区存在差异（参见 Lib:GetGMTSec 描述）
function Lib:CalcTimeFrameOpenTime(szEvent)
	-- 根据时间轴字符串 计算 相对时间秒数
	local tbMapTimeFrame = Calendar.tbMapTimeFrame
	local nDay, nTime = 0, 0
	local nOpenTime = 0
	local bRet = false

	if tbMapTimeFrame[szEvent] then
		nDay = tbMapTimeFrame[szEvent].OpenDay
		nTime = tbMapTimeFrame[szEvent].OpenTime
		bRet = true
	end
	if not bRet then
		return nOpenTime
	end
	nDay = nDay -1
	local nHour = math.floor(nTime / 100)
	local nMinute = math.mod(nTime, 100)
	local nOpenServerTime = GetServerCreateTime()
	nOpenServerTime = nOpenServerTime - math.mod((nOpenServerTime + Lib:GetGMTSec()), 3600*24)
	nOpenTime = nOpenServerTime + nDay*24*3600+nHour*3600+nMinute
	return nOpenTime
end

function Lib:CalcTimeFrameOpenDay(szEvent)
	local tbMapTimeFrame = Calendar.tbMapTimeFrame
	return tbMapTimeFrame[szEvent].OpenDay and tbMapTimeFrame[szEvent].OpenDay or 0
end

function Lib:GetStringFormTB(tbData, bNeedKey)
	local tbKeys = {}
	local szResult = ""
	for szKey, _ in pairs(tbData) do
		table.insert(tbKeys, szKey)
	end
	table.sort(tbKeys)
	local nCurIndex = 0
	for _, szKey in pairs(tbKeys) do
		if tbData[szKey] and tbData[szKey] ~= "" then
			nCurIndex = nCurIndex + 1
			if bNeedKey then
				if nCurIndex > 1 then
					szResult = string.format( "%s&%s=%s", szResult, szKey, tostring(tbData[szKey]) )
				else
					szResult = string.format( "%s=%s", szKey, tostring(tbData[szKey]) )
				end
			else
				if nCurIndex > 1 then
					szResult = string.format( "%s&%s", szResult, tostring(tbData[szKey]) )
				else
					szResult = string.format( "%s", tostring(tbData[szKey]) )
				end
			end
		end
	end
	return szResult
end

function Lib:URLDecode(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

function Lib:URLEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

Lib.tbNum2Txtmap = {
	[1] 	= "一",
	[2] 	= "二",
	[3] 	= "三",
	[4] 	= "四",
	[5] 	= "五",
	[6] 	= "六",
	[7] 	= "七",
	[8] 	= "八",
	[9] 	= "九",
	[10] 	= "十",
	[20] 	= "二十",
}
-- function Num2Txt(nNum)
-- 	if type(nNum) ~= "number" then
-- 		return
-- 	end
-- end

-- 位操作，左移
function Lib:ByteShiftLeft(nVar, nMove)
	return math.floor(nVar * (2 ^ nMove))
end

-- 位操作，右移
function Lib:ByteShiftRight(nVar, nMove)
	return math.floor(nVar / (2 ^ nMove))
end

function Lib:GetLevelDesc(nTotalLevel)
	return Player.tbLevelDesc[nTotalLevel] and Player.tbLevelDesc[nTotalLevel] or tostring(nTotalLevel)
end

function Lib:TotalLevel2MsLevel(nTotalLevel)
	return Player.tbTotalLevel2Mslevel[nTotalLevel] and Player.tbTotalLevel2Mslevel[nTotalLevel] or nTotalLevel
end

function Lib:GetMsLevelDesc(nMsLevel)
	return Player.tbMsLevelDesc[nMsLevel] and Player.tbMsLevelDesc[nMsLevel] or nMsLevel
end

function Lib:GetLevelSection(nServerOpenDay)
	local tbFindSection = nil
	for _, tbInfo in ipairs(Player.CFG_LEVELSECTION) do
		if (nServerOpenDay >= tbInfo.nOpenDay) then
			tbFindSection = tbInfo
		else
			break
		end
	end
	local nSection = tbFindSection and tbFindSection.nSection or 2
	local nMaxTotalLevel = tbFindSection and tbFindSection.nMaxTotalLevel or 39
	local szSectionName = tbFindSection and tbFindSection.szSectionName or ""
	return nSection, nMaxTotalLevel, szSectionName
end

function Lib:PickCasualOne(tbA)
	if tbA and type(tbA) == "table" then
		for _, v in pairs(tbA) do
			return v
		end
	end
end

function Lib:TrimColorTag(szStr)
	local szStr1 = string.gsub(szStr, '(<color).-(>)', "")
	local szStr2 = string.gsub(szStr1, '</color>', "")
	-- if szStr ~= szStr2 then
	-- 	LogErr("ReplaceScanner ===========", szStr, szStr1, szStr2)
	-- end
	return szStr2
end