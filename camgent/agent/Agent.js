"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.agent = void 0;
const __typia_transform__validateReport = __importStar(require("typia/lib/internal/_validateReport.js"));
const dotenv_1 = __importDefault(require("dotenv"));
const core_1 = require("@agentica/core");
const openai_1 = __importDefault(require("openai"));
const typia_1 = __importDefault(require("typia"));
dotenv_1.default.config();
const CameraSettingService_1 = require("./functions/CameraSettingService");
const FeatureExplainService_1 = require("./functions/FeatureExplainService");
const ImageScoreService_1 = require("./functions/ImageScoreService");
const SearchYoutubeService_1 = require("./functions/SearchYoutubeService");
const ImageEnhanceService_1 = require("./functions/ImageEnhanceService");
const PhotoTipService_1 = require("./functions/PhotoTipService");
exports.agent = new core_1.Agentica({
    model: "chatgpt",
    vendor: {
        api: new openai_1.default({ apiKey: process.env.OPENAI_API_KEY }),
        //model: "gpt-3.5-turbo",
        model: "gpt-4o-mini",
    },
    controllers: [
        {
            name: "Camera Setting Agent",
            protocol: "class",
            application: {
                model: "chatgpt",
                options: {
                    reference: true,
                    strict: false,
                    separate: null
                },
                functions: [
                    {
                        name: "getCameraSetting",
                        parameters: {
                            type: "object",
                            properties: {
                                situation: {
                                    type: "string"
                                }
                            },
                            required: [
                                "situation"
                            ],
                            additionalProperties: false,
                            $defs: {
                                CameraSetting: {
                                    type: "object",
                                    properties: {
                                        situation: {
                                            type: "string"
                                        },
                                        SENSOR_SENSITIVITY: {
                                            type: "number"
                                        },
                                        SENSOR_EXPOSURE_TIME: {
                                            type: "number"
                                        },
                                        COLOR_CORRECTION_MODE: {
                                            type: "string"
                                        },
                                        COLOR_CORRECTION_GAINS: {
                                            type: "array",
                                            items: {
                                                type: "number"
                                            }
                                        },
                                        LENS_FOCUS_DISTANCE: {
                                            type: "number"
                                        },
                                        CONTROL_AE_EXPOSURE_COMPENSATION: {
                                            type: "number"
                                        },
                                        CONTROL_SCENE_MODE: {
                                            type: "string"
                                        },
                                        CONTROL_AWB_LOCK: {
                                            type: "boolean"
                                        },
                                        CONTROL_AE_LOCK: {
                                            type: "boolean"
                                        },
                                        FLASH_MODE: {
                                            type: "string"
                                        },
                                        CONTROL_AF_REGIONS: {
                                            type: "string"
                                        },
                                        CONTROL_AE_REGIONS: {
                                            type: "string"
                                        },
                                        CONTROL_EFFECT_MODE: {
                                            type: "string"
                                        },
                                        NOISE_REDUCTION_MODE: {
                                            type: "string"
                                        },
                                        TONEMAP_MODE: {
                                            type: "string"
                                        },
                                        CONTROL_AE_ANTIBANDING_MODE: {
                                            type: "string"
                                        },
                                        CONTROL_AE_TARGET_FPS_RANGE: {
                                            type: "array",
                                            items: {
                                                type: "number"
                                            }
                                        },
                                        note: {
                                            type: "string"
                                        }
                                    },
                                    required: [
                                        "situation",
                                        "SENSOR_SENSITIVITY",
                                        "SENSOR_EXPOSURE_TIME",
                                        "COLOR_CORRECTION_MODE",
                                        "COLOR_CORRECTION_GAINS",
                                        "LENS_FOCUS_DISTANCE",
                                        "CONTROL_AE_EXPOSURE_COMPENSATION",
                                        "CONTROL_SCENE_MODE",
                                        "CONTROL_AWB_LOCK",
                                        "CONTROL_AE_LOCK",
                                        "FLASH_MODE",
                                        "CONTROL_AF_REGIONS",
                                        "CONTROL_AE_REGIONS",
                                        "CONTROL_EFFECT_MODE",
                                        "NOISE_REDUCTION_MODE",
                                        "TONEMAP_MODE",
                                        "CONTROL_AE_ANTIBANDING_MODE",
                                        "CONTROL_AE_TARGET_FPS_RANGE",
                                        "note"
                                    ]
                                }
                            }
                        },
                        output: {
                            $ref: "#/$defs/CameraSetting"
                        },
                        validate: (() => { const _io0 = input => "string" === typeof input.situation; const _vo0 = (input, _path, _exceptionable = true) => ["string" === typeof input.situation || _report(_exceptionable, {
                                path: _path + ".situation",
                                expected: "string",
                                value: input.situation
                            })].every(flag => flag); const __is = input => "object" === typeof input && null !== input && _io0(input); let errors; let _report; return input => {
                            if (false === __is(input)) {
                                errors = [];
                                _report = __typia_transform__validateReport._validateReport(errors);
                                ((input, _path, _exceptionable = true) => ("object" === typeof input && null !== input || _report(true, {
                                    path: _path + "",
                                    expected: "__type",
                                    value: input
                                })) && _vo0(input, _path + "", true) || _report(true, {
                                    path: _path + "",
                                    expected: "__type",
                                    value: input
                                }))(input, "$input", true);
                                const success = 0 === errors.length;
                                return success ? {
                                    success,
                                    data: input
                                } : {
                                    success,
                                    errors,
                                    data: input
                                };
                            }
                            return {
                                success: true,
                                data: input
                            };
                        }; })()
                    }
                ]
            },
            execute: new CameraSettingService_1.CameraSettingService(),
        },
        {
            name: "App Feature Explainer",
            protocol: "class",
            application: {
                model: "chatgpt",
                options: {
                    reference: true,
                    strict: false,
                    separate: null
                },
                functions: [
                    {
                        name: "listAvailableAppFunctions",
                        parameters: {
                            type: "object",
                            properties: {},
                            additionalProperties: false,
                            required: [],
                            $defs: {}
                        },
                        output: {
                            type: "string"
                        },
                        validate: (() => { const __is = input => true; let errors; let _report; return input => {
                            if (false === __is(input)) {
                                errors = [];
                                _report = __typia_transform__validateReport._validateReport(errors);
                                ((input, _path, _exceptionable = true) => true)(input, "$input", true);
                                const success = 0 === errors.length;
                                return success ? {
                                    success,
                                    data: input
                                } : {
                                    success,
                                    errors,
                                    data: input
                                };
                            }
                            return {
                                success: true,
                                data: input
                            };
                        }; })()
                    }
                ]
            },
            execute: new FeatureExplainService_1.FeatureExplainService(),
        },
        {
            name: "Image Score Evaluator",
            protocol: "class",
            application: {
                model: "chatgpt",
                options: {
                    reference: true,
                    strict: false,
                    separate: null
                },
                functions: [
                    {
                        name: "analyzeImageScore",
                        parameters: {
                            type: "object",
                            properties: {
                                imagePath: {
                                    type: "string"
                                }
                            },
                            required: [
                                "imagePath"
                            ],
                            additionalProperties: false,
                            $defs: {}
                        },
                        output: {
                            type: "string"
                        },
                        validate: (() => { const _io0 = input => "string" === typeof input.imagePath; const _vo0 = (input, _path, _exceptionable = true) => ["string" === typeof input.imagePath || _report(_exceptionable, {
                                path: _path + ".imagePath",
                                expected: "string",
                                value: input.imagePath
                            })].every(flag => flag); const __is = input => "object" === typeof input && null !== input && _io0(input); let errors; let _report; return input => {
                            if (false === __is(input)) {
                                errors = [];
                                _report = __typia_transform__validateReport._validateReport(errors);
                                ((input, _path, _exceptionable = true) => ("object" === typeof input && null !== input || _report(true, {
                                    path: _path + "",
                                    expected: "__type",
                                    value: input
                                })) && _vo0(input, _path + "", true) || _report(true, {
                                    path: _path + "",
                                    expected: "__type",
                                    value: input
                                }))(input, "$input", true);
                                const success = 0 === errors.length;
                                return success ? {
                                    success,
                                    data: input
                                } : {
                                    success,
                                    errors,
                                    data: input
                                };
                            }
                            return {
                                success: true,
                                data: input
                            };
                        }; })()
                    }
                ]
            },
            execute: new ImageScoreService_1.ImageScoreService(),
        },
        {
            name: "YouTube Finder",
            protocol: "class",
            application: {
                model: "chatgpt",
                options: {
                    reference: true,
                    strict: false,
                    separate: null
                },
                functions: [
                    {
                        name: "searchYoutube",
                        parameters: {
                            type: "object",
                            properties: {
                                situation: {
                                    type: "string"
                                }
                            },
                            required: [
                                "situation"
                            ],
                            additionalProperties: false,
                            $defs: {}
                        },
                        output: {
                            type: "string"
                        },
                        validate: (() => { const _io0 = input => "string" === typeof input.situation; const _vo0 = (input, _path, _exceptionable = true) => ["string" === typeof input.situation || _report(_exceptionable, {
                                path: _path + ".situation",
                                expected: "string",
                                value: input.situation
                            })].every(flag => flag); const __is = input => "object" === typeof input && null !== input && _io0(input); let errors; let _report; return input => {
                            if (false === __is(input)) {
                                errors = [];
                                _report = __typia_transform__validateReport._validateReport(errors);
                                ((input, _path, _exceptionable = true) => ("object" === typeof input && null !== input || _report(true, {
                                    path: _path + "",
                                    expected: "__type",
                                    value: input
                                })) && _vo0(input, _path + "", true) || _report(true, {
                                    path: _path + "",
                                    expected: "__type",
                                    value: input
                                }))(input, "$input", true);
                                const success = 0 === errors.length;
                                return success ? {
                                    success,
                                    data: input
                                } : {
                                    success,
                                    errors,
                                    data: input
                                };
                            }
                            return {
                                success: true,
                                data: input
                            };
                        }; })()
                    }
                ]
            },
            execute: new SearchYoutubeService_1.SearchYoutubeService(),
        },
        {
            name: "Image Enhancer",
            protocol: "class",
            application: {
                model: "chatgpt",
                options: {
                    reference: true,
                    strict: false,
                    separate: null
                },
                functions: [
                    {
                        name: "enhanceImage",
                        parameters: {
                            type: "object",
                            properties: {
                                imagePath: {
                                    type: "string"
                                }
                            },
                            required: [
                                "imagePath"
                            ],
                            additionalProperties: false,
                            $defs: {}
                        },
                        output: {
                            type: "string"
                        },
                        validate: (() => { const _io0 = input => "string" === typeof input.imagePath; const _vo0 = (input, _path, _exceptionable = true) => ["string" === typeof input.imagePath || _report(_exceptionable, {
                                path: _path + ".imagePath",
                                expected: "string",
                                value: input.imagePath
                            })].every(flag => flag); const __is = input => "object" === typeof input && null !== input && _io0(input); let errors; let _report; return input => {
                            if (false === __is(input)) {
                                errors = [];
                                _report = __typia_transform__validateReport._validateReport(errors);
                                ((input, _path, _exceptionable = true) => ("object" === typeof input && null !== input || _report(true, {
                                    path: _path + "",
                                    expected: "__type",
                                    value: input
                                })) && _vo0(input, _path + "", true) || _report(true, {
                                    path: _path + "",
                                    expected: "__type",
                                    value: input
                                }))(input, "$input", true);
                                const success = 0 === errors.length;
                                return success ? {
                                    success,
                                    data: input
                                } : {
                                    success,
                                    errors,
                                    data: input
                                };
                            }
                            return {
                                success: true,
                                data: input
                            };
                        }; })()
                    }
                ]
            },
            execute: new ImageEnhanceService_1.ImageEnhanceService(),
        },
        {
            name: "Photo Tip",
            protocol: "class",
            application: {
                model: "chatgpt",
                options: {
                    reference: true,
                    strict: false,
                    separate: null
                },
                functions: [
                    {
                        name: "getPhotoTip",
                        parameters: {
                            type: "object",
                            properties: {
                                situation: {
                                    type: "string"
                                }
                            },
                            required: [
                                "situation"
                            ],
                            additionalProperties: false,
                            $defs: {}
                        },
                        output: {
                            type: "string"
                        },
                        validate: (() => { const _io0 = input => "string" === typeof input.situation; const _vo0 = (input, _path, _exceptionable = true) => ["string" === typeof input.situation || _report(_exceptionable, {
                                path: _path + ".situation",
                                expected: "string",
                                value: input.situation
                            })].every(flag => flag); const __is = input => "object" === typeof input && null !== input && _io0(input); let errors; let _report; return input => {
                            if (false === __is(input)) {
                                errors = [];
                                _report = __typia_transform__validateReport._validateReport(errors);
                                ((input, _path, _exceptionable = true) => ("object" === typeof input && null !== input || _report(true, {
                                    path: _path + "",
                                    expected: "__type",
                                    value: input
                                })) && _vo0(input, _path + "", true) || _report(true, {
                                    path: _path + "",
                                    expected: "__type",
                                    value: input
                                }))(input, "$input", true);
                                const success = 0 === errors.length;
                                return success ? {
                                    success,
                                    data: input
                                } : {
                                    success,
                                    errors,
                                    data: input
                                };
                            }
                            return {
                                success: true,
                                data: input
                            };
                        }; })()
                    }
                ]
            },
            execute: new PhotoTipService_1.PhotoTipService(),
        }
    ],
});
