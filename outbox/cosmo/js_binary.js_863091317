var UInt4 = function (value) {
	return (value & 0xF);
};

var Int4 = function (value) {
	var ref = UInt4(value);
	return (ref > 0x7) ? ref - 0x10 : ref;
};

var UInt8 = function (value) {
	return (value & 0xFF);
};

var Int8 = function (value) {
	var ref = UInt8(value);
	return (ref > 0x7F) ? ref - 0x100 : ref;
};

var UInt16 = function (value) {
	return (value & 0xFFFF);
};

var Int16 = function (value) {
	var ref = UInt16(value);
	return (ref > 0x7FFF) ? ref - 0x10000 : ref;
};
