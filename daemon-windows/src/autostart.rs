// Windows registry autostart management

#[cfg(windows)]
pub fn register() {
    use std::ffi::OsStr;
    use std::os::windows::ffi::OsStrExt;
    use windows_sys::Win32::System::Registry::*;

    let exe_path = std::env::current_exe().unwrap_or_default();
    let exe_str = exe_path.to_string_lossy();

    let key_path: Vec<u16> = OsStr::new("Software\\Microsoft\\Windows\\CurrentVersion\\Run")
        .encode_wide()
        .chain(std::iter::once(0))
        .collect();

    let value_name: Vec<u16> = OsStr::new("MouseStride")
        .encode_wide()
        .chain(std::iter::once(0))
        .collect();

    let value_data: Vec<u16> = OsStr::new(&*exe_str)
        .encode_wide()
        .chain(std::iter::once(0))
        .collect();

    unsafe {
        let mut hkey = 0isize;
        let result = RegCreateKeyExW(
            HKEY_CURRENT_USER,
            key_path.as_ptr(),
            0,
            std::ptr::null(),
            0,
            KEY_WRITE,
            std::ptr::null(),
            &mut hkey,
            std::ptr::null_mut(),
        );

        if result == 0 {
            RegSetValueExW(
                hkey,
                value_name.as_ptr(),
                0,
                REG_SZ,
                value_data.as_ptr() as *const u8,
                (value_data.len() * 2) as u32,
            );
            RegCloseKey(hkey);
        }
    }
}

#[cfg(not(windows))]
pub fn register() {
    // no-op on non-Windows
}
