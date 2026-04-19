"""
MATH PROJECT: TÍCH PHÂN ĐA CẤP - PHIÊN BẢN ỨNG DỤNG THỰC TẾ (Tkinter)
================================================================
Tác giả: Nhóm 49
Mô tả: 
    - Minh họa 4 bài toán tích phân bội mới theo đề bài (cập nhật 2026):
      Bài 1: Khối lượng cột trụ bê tông (mật độ thay đổi theo r)
      Bài 2: Khối lượng hành tinh (mật độ thay đổi theo khoảng cách từ tâm)
      Bài 3: Xác suất đạt chuẩn robot hàn (phân bố Gaussian 2D)
      Bài 4: Mô-men quán tính bánh đà xi lanh (Vật lý kỹ thuật)
    - Giao diện tab chuyên nghiệp, biểu đồ nhúng trực tiếp.
    - Phần giải thích toán học đã được viết CHI TIẾT theo phương pháp ĐỔI BIẾN.
    - Dễ mở rộng: chỉ cần thêm compute_ + create_plot_ + explanation.

Mục tiêu dự án:
- Áp dụng tích phân bội vào bài toán thực tế (xây dựng, thiên văn, robot, cơ khí).
- Sử dụng phương pháp đổi biến (tọa độ trụ, cầu, cực) để đơn giản hóa.
- So sánh kết quả số (SciPy) với giá trị chính xác.
"""

import numpy as np
from scipy import integrate
from matplotlib.figure import Figure
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2Tk
import tkinter as tk
from tkinter import ttk
from tkinter import messagebox

# =====================================================================
# CÁC HÀM TÍNH TOÁN (không phụ thuộc GUI)
# =====================================================================
def compute_bai1():
    # Bài 1: Khối lượng cột trụ (mật độ thay đổi)
    # ρ(x,y,z) = 1 + √(x² + y²) = 1 + r
    # Dùng tọa độ trụ: dV = r dz dr dθ
    def bai1(z, r, theta):
        return (1 + r) * r                     # ρ * Jacobian

    ket_qua, loi = integrate.tplquad(
        bai1,
        0, 2*np.pi,
        lambda theta: 0, lambda theta: 2,
        lambda theta, r: 0, lambda theta, r: 5
    )
    chinh_xac = 140 * np.pi / 3
    return ket_qua, loi, chinh_xac


def compute_bai2():
    # Bài 2: Khối lượng hành tinh (mật độ thay đổi)
    # ρ(x,y,z) = 1 / (1 + √(x² + y² + z²)) = 1 / (1 + ρ)
    # Dùng tọa độ cầu: dV = ρ² sinφ dρ dφ dθ
    def bai2(rho, phi, theta):
        return (1 / (1 + rho)) * (rho ** 2) * np.sin(phi)

    ket_qua, loi = integrate.tplquad(
        bai2,
        0, 2*np.pi,                  # theta
        lambda theta: 0, lambda theta: np.pi,          # phi
        lambda theta, phi: 0, lambda theta, phi: 3     # rho
    )
    chinh_xac = 4 * np.pi * (1.5 + np.log(4))
    return ket_qua, loi, chinh_xac


def compute_bai3():
    # Bài 3: Xác suất đạt chuẩn robot hàn (Gaussian 2D)
    # f(x,y) = e^{-(x²+y²)}
    # Xác suất = (∫∫_{r≤1} f dA) / (tổng ∫∫ f dA) = integral / π
    def bai3(r, theta):
        return np.exp(-r**2) * r               # Jacobian r

    integral, loi = integrate.dblquad(
        bai3,
        0, 2*np.pi,
        lambda theta: 0,
        lambda theta: 1
    )
    xac_suat = integral / np.pi
    chinh_xac = 1 - np.exp(-1)
    return xac_suat, loi, chinh_xac            # ket_qua = xác suất


def compute_bai4():
    # Bài 4: Mô-men quán tính bánh đà xi lanh
    # I_z = ∭ (x² + y²) ρ dV , ρ = 10 kg/m³
    # Tọa độ trụ: x² + y² = r², dV = r dz dr dθ
    density = 10

    def bai4(z, r, theta):
        return density * r**3

    ket_qua, loi = integrate.tplquad(
        bai4,
        0, 2*np.pi,
        lambda theta: 0, lambda theta: 4,
        lambda theta, r: 0, lambda theta, r: 5
    )
    chinh_xac = 6400 * np.pi
    return ket_qua, loi, chinh_xac


# =====================================================================
# CÁC HÀM VẼ BIỂU ĐỒ
# =====================================================================
def create_plot_bai1():   # Cột trụ (Bài 1)
    fig = Figure(figsize=(6, 6))
    ax = fig.add_subplot()
    theta = np.linspace(0, 2*np.pi, 100)
    r = np.linspace(0, 2, 50)
    Theta, R = np.meshgrid(theta, r)
    X = R * np.cos(Theta)
    Y = R * np.sin(Theta)
    cf = ax.contourf(X, Y, R, levels=20)
    ax.set_aspect('equal')
    ax.set_title('Bài 1: Cột trụ R=2m (mật độ 1+r)')
    ax.set_xlabel('x')
    ax.set_ylabel('y')
    fig.colorbar(cf, ax=ax, label="r")
    return fig


def create_plot_bai2():   # Hành tinh (Bài 2)
    fig = Figure(figsize=(7, 6))
    ax = fig.add_subplot(projection='3d')
    u = np.linspace(0, 2*np.pi, 50)
    v = np.linspace(0, np.pi, 50)
    x = np.outer(np.cos(u), np.sin(v))
    y = np.outer(np.sin(u), np.sin(v))
    z = np.outer(np.ones(np.size(u)), np.cos(v))
    ax.plot_surface(x, y, z, alpha=0.8)
    ax.set_title('Bài 2: Hành tinh R=3 (nghìn km)')
    ax.set_xlabel('x')
    ax.set_ylabel('y')
    ax.set_zlabel('z')
    return fig


def create_plot_bai3():   # Gaussian 3D
    fig = Figure(figsize=(7, 6))
    ax = fig.add_subplot(projection='3d')
    r = np.linspace(0, 1, 50)
    theta = np.linspace(0, 2*np.pi, 100)
    R, Theta = np.meshgrid(r, theta)
    X = R * np.cos(Theta)
    Y = R * np.sin(Theta)
    Z = np.exp(-R**2)
    ax.plot_surface(X, Y, Z, alpha=0.8, cmap='viridis')
    ax.set_title('Bài 3: Gaussian 3D (bề mặt trên đĩa r ≤ 1 mm)')
    ax.set_xlabel('x (mm)')
    ax.set_ylabel('y (mm)')
    ax.set_zlabel('f(x,y)')
    return fig


def create_plot_bai4():   # Bánh đà xi lanh 3D
    fig = Figure(figsize=(7, 6))
    ax = fig.add_subplot(projection='3d')
    R = 4.0
    H = 5.0

    # Lateral surface (thân trụ)
    theta = np.linspace(0, 2*np.pi, 60)
    z = np.linspace(0, H, 40)
    Theta, Z = np.meshgrid(theta, z)
    X = R * np.cos(Theta)
    Y = R * np.sin(Theta)
    ax.plot_surface(X, Y, Z, alpha=0.6, color='red', edgecolor='none')

    # Top & Bottom disks
    r_disk = np.linspace(0, R, 30)
    theta_disk = np.linspace(0, 2*np.pi, 60)
    Rr, Theta_disk = np.meshgrid(r_disk, theta_disk)
    X_disk = Rr * np.cos(Theta_disk)
    Y_disk = Rr * np.sin(Theta_disk)

    Z_top = np.full_like(X_disk, H)
    ax.plot_surface(X_disk, Y_disk, Z_top, alpha=0.7, color='darkred', edgecolor='none')
    Z_bot = np.zeros_like(X_disk)
    ax.plot_surface(X_disk, Y_disk, Z_bot, alpha=0.7, color='darkred', edgecolor='none')

    ax.set_title('Bài 4: Bánh đà xi lanh 3D (R=4m, H=5m)')
    ax.set_xlabel('x')
    ax.set_ylabel('y')
    ax.set_zlabel('z')
    return fig


# =====================================================================
# HÀM TẠO TAB CHUNG
# =====================================================================
def create_problem_tab(notebook, title, compute_func, create_plot_func, explanation):
    tab = ttk.Frame(notebook)
    notebook.add(tab, text=title)

    left_frame = ttk.Frame(tab)
    left_frame.pack(side='left', fill='both', expand=False, padx=10, pady=10)

    right_frame = ttk.Frame(tab)
    right_frame.pack(side='right', fill='both', expand=True, padx=10, pady=10)

    # Lý thuyết
    ttk.Label(left_frame, text="Giải thích toán học & ứng dụng", font=("Arial", 18, "bold")).pack(anchor='w')
    theory = tk.Text(left_frame, width=40, wrap='word', font=("Arial", 15))
    theory.insert('1.0', explanation)
    theory.config(state='disabled')
    theory.pack(fill='both', expand=True)

    # Kết quả
    result_frame = ttk.LabelFrame(right_frame, text="Kết quả tính toán")
    result_frame.pack(fill='x', pady=(0, 10))
    result_label = ttk.Label(result_frame, text="Nhấn nút để tính toán...", justify='left', anchor='w')
    result_label.pack(padx=15, pady=15, fill='x')

    def on_compute():
        try:
            ket_qua, loi, chinh_xac = compute_func()
            text = (f"Kết quả: {ket_qua:.6f}\n"
                    f"Sai số: {loi:.2e}\n"
                    f"Giá trị đúng: {chinh_xac:.6f}")
            result_label.config(text=text)

            # Xóa và vẽ lại biểu đồ
            for widget in plot_area.winfo_children():
                widget.destroy()
            fig = create_plot_func()
            canvas = FigureCanvasTkAgg(fig, master=plot_area)
            canvas.draw()
            canvas.get_tk_widget().pack(fill='both', expand=True)

            toolbar_frame = ttk.Frame(plot_area)
            toolbar_frame.pack(fill='x')
            NavigationToolbar2Tk(canvas, toolbar_frame).update()

        except Exception as e:
            messagebox.showerror("Lỗi", f"Có lỗi xảy ra:\n{str(e)}")

    ttk.Button(right_frame, text="🚀 Tính Toán & Vẽ Biểu Đồ", command=on_compute).pack(pady=8)

    # Khu vực biểu đồ
    plot_area = ttk.LabelFrame(right_frame, text="Biểu đồ minh họa")
    plot_area.pack(fill='both', expand=True)
    plot_area.rowconfigure(0, weight=1)
    plot_area.columnconfigure(0, weight=1)

    return tab


# =====================================================================
# GUI CHÍNH
# =====================================================================
root = tk.Tk()
root.title("MATH PROJECT - Tích Phân Đa Cấp Ứng Dụng Thực Tế")
root.geometry("1100x720")
root.state('zoomed')

style = ttk.Style()
style.theme_use('clam')

notebook = ttk.Notebook(root)
notebook.pack(fill='both', expand=True, padx=10, pady=10)

# === TAB GIỚI THIỆU ===
intro_tab = ttk.Frame(notebook)
notebook.add(intro_tab, text="📖 Giới Thiệu Dự Án")

intro_text = """MATH PROJECT: TÍCH PHÂN ĐA CẤP ỨNG DỤNG THỰC TẾ

4 bài toán mới theo đề bài:
• Bài 1: Khối lượng cột trụ bê tông (mật độ thay đổi)
• Bài 2: Khối lượng hành tinh (mật độ thay đổi)
• Bài 3: Xác suất robot hàn (Gaussian 2D)
• Bài 4: Mô-men quán tính bánh đà xi lanh

Tác giả: Nhóm 49
Công cụ: Python + Tkinter + SciPy + Matplotlib

Cách sử dụng: Chọn tab → Nhấn "Tính Toán & Vẽ Biểu Đồ"
"""

tk.Label(intro_tab, text=intro_text, justify='left', font=("Arial", 15), wraplength=1000).pack(pady=100, padx=100)

# === CÁC TAB BÀI TOÁN (đã viết CHI TIẾT theo phương pháp đổi biến) ===
bai1_explain = """BÀI 1: Cột trụ bê tông (xây dựng cầu đường)

Công thức gốc (tọa độ Descartes):
M = ∭ (1 + √(x² + y²)) dx dy dz

Phương pháp đổi biến:
Đặt: x = r cosθ, y = r sinθ, z = z
Jacobian: |J| = r
Giới hạn mới: r ∈ [0, 2], θ ∈ [0, 2π], z ∈ [0, 5]

Tích phân sau đổi biến:
M = ∫₀²π ∫₀² ∫₀⁵ (1 + r) · r dz dr dθ

Kết quả: 140π/3 ≈ 146.6077 (kg)"""

create_problem_tab(notebook, "Bài 1 (Cột trụ)", compute_bai1, create_plot_bai1, bai1_explain)


bai2_explain = """BÀI 2: Hành tinh (vật lý thiên văn)

Công thức gốc (tọa độ Descartes):
M = ∭ [1 / (1 + √(x² + y² + z²))] dx dy dz

Phương pháp đổi biến:
Đặt: x = ρ sinφ cosθ, y = ρ sinφ sinθ, z = ρ cosφ
Jacobian: |J| = ρ² sinφ
Giới hạn mới: ρ ∈ [0, 3], φ ∈ [0, π], θ ∈ [0, 2π]

Tích phân sau đổi biến:
M = ∫₀²π ∫₀π ∫₀³ [1/(1+ρ)] · ρ² sinφ dρ dφ dθ

Kết quả: 4π (3/2 + ln 4) ≈ 36.27 (đơn vị khối lượng)"""

create_problem_tab(notebook, "Bài 2 (Hành tinh)", compute_bai2, create_plot_bai2, bai2_explain)


bai3_explain = """BÀI 3: Robot hàn tự động (sai số theo phân bố Gaussian)

Công thức gốc (tọa độ Descartes):
P = (1/π) ∬_{x²+y² ≤ 1} e^{-(x² + y²)} dx dy

Phương pháp đổi biến:
Đặt: x = r cosθ, y = r sinθ
Jacobian: |J| = r
Giới hạn mới: r ∈ [0, 1], θ ∈ [0, 2π]

Tích phân sau đổi biến:
P = (1/π) ∫₀²π ∫₀¹ e^{-r²} · r dr dθ = 1 − e⁻¹ ≈ 0.6321

Kết quả: Tỷ lệ thành phẩm ≈ 63.21%"""

create_problem_tab(notebook, "Bài 3 (Robot hàn)", compute_bai3, create_plot_bai3, bai3_explain)


bai4_explain = """BÀI 4: Mô-men quán tính bánh đà (thiết kế máy)

Công thức gốc (tọa độ Descartes):
I_z = ∭ (x² + y²) · ρ dx dy dz     (ρ = 10 kg/m³)

Phương pháp đổi biến:
Đặt: x = r cosθ, y = r sinθ, z = z
Jacobian: |J| = r
Giới hạn mới: r ∈ [0, 4], θ ∈ [0, 2π], z ∈ [0, 5]

Tích phân sau đổi biến:
I_z = ∫₀²π ∫₀⁴ ∫₀⁵ r² · ρ · r dz dr dθ
    = 10 · ∫₀²π dθ · ∫₀⁴ r³ dr · ∫₀⁵ dz

Kết quả: 6400π ≈ 20106.192 (kg·m²)"""

create_problem_tab(notebook, "Bài 4 (Mô-men quán tính)", compute_bai4, create_plot_bai4, bai4_explain)
# Nút Thoát
bottom_frame = ttk.Frame(root)
bottom_frame.pack(fill='x', pady=5)
ttk.Button(bottom_frame, text="❌ Thoát chương trình", command=root.quit).pack(side='right', padx=20)

root.mainloop()