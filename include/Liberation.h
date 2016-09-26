//--------------------------------//
//-----------Liberation-----------//
//-------Created-by-Razzile-------//
//--------------------------------//
//------Don't mess with this------//
//------Unless you are smart------//
//--------------------------------//
//------------Licenses------------//
//--------------------------------//
// Copyright (c) 2016, Razzile

// Permission to use, copy, modify, and/or distribute this software for any
// purpose
// with or without fee is hereby granted, provided that the above copyright
// notice
// and this permission notice appear in all copies.

// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
// REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
// AND
// FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
// INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
// LOSS
// OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
// OTHER
// TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
// OF
// THIS SOFTWARE.

#if __cplusplus <= 199711L
#error Please enable C++11 for use with Liberation
#endif

#include <CoreFoundation/CoreFoundation.h>
#include <mach/mach.h>
#include <sstream>
#include <string>
#include <sys/types.h>
#include <vector>

#define hidden __attribute__((visibility("hidden")))

/* Container namespace for classes */
inline namespace liberation {

using bytes = std::vector<uint8_t>;

enum class ARMv7Mode { ARM, Thumb };

class Patch {
public:
  static Patch *CreatePatch(vm_address_t address, uint32_t data);
  static Patch *CreatePatch(vm_address_t address, std::string data);
  static Patch *CreateRawPatch(vm_address_t addr, char *data, size_t len);
  static Patch *CreateInstrPatch(vm_address_t address, std::string instr,
                                 ARMv7Mode mode = ARMv7Mode::Thumb);

  virtual bool Apply();
  virtual bool Reset();

private:
  Patch() = default;
  Patch(vm_address_t addr, char *data, size_t len);
  ~Patch();

protected:
  vm_address_t _address;
  bytes _patchBytes;
  bytes _origBytes;
  size_t _patchSize;
};

class Hook {
public:
  ~Hook();
  Hook(std::string symbol, void *hookPtr, void **origPtr);
  Hook(std::string symbol, void *hookPtr);
  Hook(void *hookFuncAddr, void *hookPtr, void **origPtr);
  Hook(void *hookFuncAddr, void *hookPtr);
  Hook(vm_address_t hookFuncAddr, void *hookPtr, void **origPtr);
  Hook(vm_address_t hookFuncAddr, void *hookPtr);

  template <typename T>
  hidden Hook(void *hookFuncAddress, T *hookPtr, T **origPtr)
      : Hook(hookFuncAddress, (void *)hookPtr, (void **)origPtr) {}

  template <typename T>
  hidden Hook(void *hookFuncAddress, T *hookPtr)
      : Hook(hookFuncAddress, (void *)hookPtr) {}

  template <typename T>
  hidden Hook(vm_address_t hookFuncAddr, T *hookPtr, T **origPtr)
      : Hook((void *)(hookFuncAddr), (void *)hookPtr, (void **)origPtr) {}

  template <typename T>
  hidden Hook(vm_address_t hookFuncAddr, T *hookPtr)
      : Hook((void *)(hookFuncAddr), (void *)hookPtr) {}

  bool Apply();
  bool Reset();

private:
  std::string _symbol;
  void *_hookPtr;
  void **_origPtr;
  void *_hookFuncAddr;
};

class Settings {
public:
  Settings(const char *path);
  ~Settings();

  int GetPrefInt(const char *key);
  float GetPrefFloat(const char *key);
  bool GetPrefBool(const char *key);

  __attribute__((noinline)) bool reloadSettings();

  class settings_proxy {
  public:
    char *key;

    union Value {
      int asInt;
      bool asBool;
      float asFloat;
    } value;

    enum ValueType { Int, Bool, Float } valueType;

    Settings *container;

    hidden settings_proxy(const char *_key) {
      key = (char *)malloc(strlen(_key));
      strcpy(key, _key);
    }

    hidden settings_proxy(int val) {
      value.asInt = val;
      valueType = Int;
    }

    hidden settings_proxy(float val) {
      value.asFloat = val;
      valueType = Float;
    }

    hidden settings_proxy(bool val) {
      value.asBool = val;
      valueType = Bool;
    }

    hidden operator int() { return container->GetPrefInt(key); }

    hidden operator float() { return container->GetPrefFloat(key); }

    hidden operator bool() { return container->GetPrefBool(key); }

    hidden settings_proxy &operator=(const settings_proxy &source) {
      switch (source.valueType) {
      case Int: {
        set(source.value.asInt);
        break;
      }
      case Bool: {
        set(source.value.asBool);
        break;
      }
      case Float: {
        set(source.value.asFloat);
        break;
      }
      }
      return *this;
    }
    void set(bool value);
    void set(int value);
    void set(float value);

    hidden ~settings_proxy() {
      if (key != NULL)
        free(key);
    }
  };

  hidden settings_proxy operator[](const char *key) {
    settings_proxy proxy(key);
    proxy.container = this;
    return proxy;
  }

private:
  const char *path;
  CFDictionaryRef dict;
};
} // utils
