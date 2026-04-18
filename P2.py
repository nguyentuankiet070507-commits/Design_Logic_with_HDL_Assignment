"""
MATH PROJECT: TÍCH PHÂN ĐA CẤP - PHIÊN BẢN NÂNG CẤP GUI (Tkinter)
================================================================
Tác giả: Nhóm 49
Mô tả: 
    - Minh họa 5 bài toán tích phân bội (double & triple integrals) trong các hệ tọa độ:
      Descartes, Cylindrical, Spherical, Gaussian 2D (ứng dụng AI/ML), Moment of Inertia (ứng dụng Vật lý).
    - Giao diện tab chuyên nghiệp, biểu đồ nhúng trực tiếp vào cửa sổ.
    - Phần giải thích lý thuyết cho từng bài → dễ trình bày dự án Toán học.
    - Dễ mở rộng: chỉ cần thêm compute_ + create_plot_ + explanation là có tab mới.
    - Ứng dụng: Calculus nâng cao, Vật lý, Xác suất, AI/ML.

Mục tiêu dự án:
- Hiểu rõ sự thay đổi hệ tọa độ để đơn giản hóa tích phân.
- Trực quan hóa miền tích phân qua biểu đồ 2D/3D.
- So sánh kết quả số với giá trị chính xác.
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
    # Đổi biến: x = u, y = 2v
    # Khi đó dx dy = |J| du dv = 2 du dv
    # I = ∫₀¹ ∫₀¹ 2(u² + (2v)²) dv du
    def bai1(v, u):
        return 2 * (u**2 + (2 * v)**2)

    ket_qua, loi = integrate.dblquad(bai1, 0, 1, 0, 1)
    chinh_xac = 10 / 3
    return ket_qua, loi, chinh_xac


def compute_bai2():
    # Đổi biến sang tọa độ trụ:
    # x = r cosθ, y = r sinθ, z = z
    # Jacobian: dV = r dz dr dθ
    # Mật độ: 1 + r
    def bai2(z, r, theta):
        return (1 + r) * r

    ket_qua, loi = integrate.tplquad(
        bai2,
        0, 2*np.pi,
        lambda theta: 0, lambda theta: 2,
        lambda theta, r: 0, lambda theta, r: 5
    )
    chinh_xac = 140 * np.pi / 3
    return ket_qua, loi, chinh_xac


def compute_bai3():
    # Đổi biến sang tọa độ cầu:
    # x = ρ sinφ cosθ, y = ρ sinφ sinθ, z = ρ cosφ
    # Jacobian: dV = ρ² sinφ dρ dφ dθ
    def bai3(rho, phi, theta):
        return rho**2 * np.sin(phi)

    ket_qua, loi = integrate.tplquad(
        bai3,
        0, 2*np.pi,
        lambda theta: 0, lambda theta: np.pi,
        lambda theta, phi: 0, lambda theta, phi: 1
    )
    chinh_xac = 4 * np.pi / 3
    return ket_qua, loi, chinh_xac


def compute_bai4():
    # Đổi biến sang tọa độ cực:
    # x = r cosθ, y = r sinθ
    # Jacobian: dA = r dr dθ
    def bai4(r, theta):
        return np.exp(-r**2) * r

    ket_qua, loi = integrate.dblquad(
        bai4,
        0, 2*np.pi,
        lambda theta: 0,
        lambda theta: 1
    )
    chinh_xac = np.pi * (1 - np.exp(-1))
    return ket_qua, loi, chinh_xac


def compute_bai5():
    # Mô-men quán tính quanh trục z:
    # I_z = ∭ ρ(x²+y²) dV
    # Với tọa độ trụ: x²+y² = r², dV = r dz dr dθ
    # => integrand = density * r³
    density = 10

    def bai5(z, r, theta):
        return density * r**3

    ket_qua, loi = integrate.tplquad(
        bai5,
        0, 2*np.pi,
        lambda theta: 0, lambda theta: 4,
        lambda theta, r: 0, lambda theta, r: 5
    )
    chinh_xac = 6400 * np.pi
    return ket_qua, loi, chinh_xac


# =====================================================================
# CÁC HÀM VẼ BIỂU ĐỒ (trả về Figure để nhúng vào Tkinter)
# =====================================================================
def create_plot_bai1():
    fig = Figure(figsize=(7, 6))
    ax = fig.add_subplot(projection='3d')
    x = np.linspace(0, 1, 50)
    y = np.linspace(0, 2, 50)
    X, Y = np.meshgrid(x, y)
    Z = X**2 + Y**2
    ax.plot_surface(X, Y, Z, alpha=0.8)
    ax.set_title('Bài 1: z = x² + y² (Descartes)')
    ax.set_xlabel('x')
    ax.set_ylabel('y')
    ax.set_zlabel('z')
    return fig


def create_plot_bai2():
    fig = Figure(figsize=(6, 6))
    ax = fig.add_subplot()
    theta = np.linspace(0, 2*np.pi, 100)
    r = np.linspace(0, 2, 50)
    Theta, R = np.meshgrid(theta, r)
    X = R * np.cos(Theta)
    Y = R * np.sin(Theta)
    cf = ax.contourf(X, Y, R, levels=20)
    ax.set_aspect('equal')
    ax.set_title('Bài 2: Tích phân trụ (Cylindrical)')
    ax.set_xlabel('x')
    ax.set_ylabel('y')
    fig.colorbar(cf, ax=ax, label="r")
    return fig


def create_plot_bai3():
    fig = Figure(figsize=(6, 6))
    ax = fig.add_subplot(projection='3d')
    u = np.linspace(0, 2*np.pi, 50)
    v = np.linspace(0, np.pi, 50)
    x = np.outer(np.cos(u), np.sin(v))
    y = np.outer(np.sin(u), np.sin(v))
    z = np.outer(np.ones(np.size(u)), np.cos(v))
    ax.plot_surface(x, y, z, alpha=0.8)
    ax.set_title('Bài 3: Tích phân cầu (Spherical)')
    ax.set_xlabel('x')
    ax.set_ylabel('y')
    ax.set_zlabel('z')
    return fig


def create_plot_bai4():
    fig = Figure(figsize=(6, 6))
    ax = fig.add_subplot()
    grid = np.linspace(-1.6, 1.6, 400)
    X, Y = np.meshgrid(grid, grid)
    Z = np.exp(-(X**2 + Y**2))
    cf = ax.contourf(X, Y, Z, levels=20)
    theta = np.linspace(0, 2*np.pi, 300)
    ax.plot(np.cos(theta), np.sin(theta), linewidth=2, color='red')
    ax.set_aspect('equal')
    ax.set_title('Bài 4: Gaussian 2D (AI/ML)')
    ax.set_xlabel('x')
    ax.set_ylabel('y')
    fig.colorbar(cf, ax=ax, label=r"$f(x,y)=e^{-(x^2+y^2)}$")
    return fig


def create_plot_bai5():
    fig = Figure(figsize=(6, 6))
    ax = fig.add_subplot()
    theta = np.linspace(0, 2*np.pi, 100)
    r = np.linspace(0, 4, 50)
    Theta, R = np.meshgrid(theta, r)
    X = R * np.cos(Theta)
    Y = R * np.sin(Theta)
    cf = ax.contourf(X, Y, R, levels=20)
    ax.set_aspect('equal')
    ax.set_title('Bài 5: Moment of Inertia (Cylinder)')
    ax.set_xlabel('x')
    ax.set_ylabel('y')
    fig.colorbar(cf, ax=ax, label="r")
    return fig


# =====================================================================
# HÀM TẠO TAB CHUNG (rất dễ mở rộng)
# =====================================================================
def create_problem_tab(notebook, title, compute_func, create_plot_func, explanation, result_title="Kết quả sau khi đổi biến:"):
    tab = ttk.Frame(notebook)
    notebook.add(tab, text=title)

    # === Layout: Trái = Lý thuyết | Phải = Kết quả + Biểu đồ ===
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

    # Nút tính toán
    def on_compute():
        try:
            ket_qua, loi, chinh_xac = compute_func()
            text = (f"{result_title}\n"
                    f"Kết quả: {ket_qua:.6f}\n"
                    f"Sai số: {loi:.2e}\n"
                    f"Giá trị đúng: {chinh_xac:.6f}")
            result_label.config(text=text)

            # Xóa biểu đồ cũ
            for widget in plot_area.winfo_children():
                widget.destroy()

            # Tạo & nhúng biểu đồ mới
            fig = create_plot_func()
            canvas = FigureCanvasTkAgg(fig, master=plot_area)
            canvas.draw()
            canvas.get_tk_widget().pack(fill='both', expand=True)

            # Thanh công cụ (zoom, pan, save...)
            toolbar_frame = ttk.Frame(plot_area)
            toolbar_frame.pack(fill='x')
            toolbar = NavigationToolbar2Tk(canvas, toolbar_frame)
            toolbar.update()

        except Exception as e:
            messagebox.showerror("Lỗi", f"Có lỗi xảy ra:\n{str(e)}")

    compute_btn = ttk.Button(right_frame, text="🚀 Tính Toán & Vẽ Biểu Đồ", command=on_compute)
    compute_btn.pack(pady=8)

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
root.title("MATH PROJECT - Tích Phân Hàm Nhiều Biến")
root.geometry("1100x720")
root.state('zoomed')  # fullscreen cho trình bày dự án

# Style hiện đại hơn
style = ttk.Style()
style.theme_use('clam')

# Notebook (tabs)
notebook = ttk.Notebook(root)
notebook.pack(fill='both', expand=True, padx=10, pady=10)

# === TAB GIỚI THIỆU DỰ ÁN ===
intro_tab = ttk.Frame(notebook)
notebook.add(intro_tab, text="📖 Giới Thiệu Dự Án")

intro_text = """MATH PROJECT: TÍCH PHÂN HÀM NHIỀU BIẾN

Phiên bản nâng cấp hoàn chỉnh:
• Giao diện tab chuyên nghiệp
• Biểu đồ nhúng trực tiếp (không pop-up)
• Giải thích lý thuyết chi tiết
• Dễ mở rộng & trình bày

Mục tiêu học tập:
• Hiểu cách chuyển đổi hệ tọa độ để tính tích phân bội dễ dàng hơn.
• Ứng dụng thực tế: Vật lý (mô-men quán tính), AI/ML (Gaussian kernel), hình học.
• So sánh kết quả số (scipy) với giá trị chính xác.

Công cụ: Python + Tkinter + SciPy + Matplotlib

Cách sử dụng: Chọn tab → Nhấn nút "Tính Toán & Vẽ Biểu Đồ"
"""

tk.Label(intro_tab, text=intro_text, justify='left', font=("Arial", 15), wraplength=1000).pack(pady=100, padx=100)

# === CÁC TAB BÀI TOÁN ===
bai1_explain = """BÀI 1: Tích phân kép trong tọa độ Descartes
∫₀¹ ∫₀² (x² + y²) dy dx

Đặt x = u, y = 2v
⇒ dx dy = 2 du dv
⇒ ∫₀¹ ∫₀¹ 2(u² + 4v²) dv du

• Miền: Hình chữ nhật.
• Ứng dụng: Tính thể tích vật thể nằm dưới mặt phẳng z = x² + y²."""

create_problem_tab(notebook, "Bài 1 (Descartes)", compute_bai1, create_plot_bai1, bai1_explain)


bai2_explain = """BÀI 2: Tích phân ba trong tọa độ trụ (Cylindrical)
∫∫∫ (1 + r)·r dz dr dθ

Đặt x = r cosθ, y = r sinθ, z = z
⇒ dV = r dz dr dθ

• Miền: Xy lanh bán kính 2, cao 5.
• Ưu điểm: Jacobian = r → dễ tính hơn Descartes."""

create_problem_tab(notebook, "Bài 2 (Cylindrical)", compute_bai2, create_plot_bai2, bai2_explain)


bai3_explain = """BÀI 3: Tích phân ba trong tọa độ cầu (Spherical)
∫∫∫ ρ² sinφ dρ dφ dθ

Đặt x = ρ sinφ cosθ, y = ρ sinφ sinθ, z = ρ cosφ
⇒ dV = ρ² sinφ dρ dφ dθ

• Miền: Hình cầu bán kính 1.
• Ưu điểm: Jacobian = ρ² sinφ → cực kỳ đơn giản cho vật thể cầu."""

create_problem_tab(notebook, "Bài 3 (Spherical)", compute_bai3, create_plot_bai3, bai3_explain)


bai4_explain = """BÀI 4: Gaussian 2D (ứng dụng AI/ML)
∫₀²π ∫₀¹ e⁻ʳ² · r dr dθ

Đặt x = r cosθ, y = r sinθ
⇒ dA = r dr dθ

• Đây là phân phối Gaussian 2D trên đĩa đơn vị.
• Ứng dụng thực tế: Kernel Gaussian trong Machine Learning, xử lý ảnh, xác suất."""
create_problem_tab(notebook, "Bài 4 (Gaussian AI/ML)", compute_bai4, create_plot_bai4, bai4_explain)

bai5_explain = """BÀI 5: Mô-men quán tính của xi lanh (Vật lý)
I_z = ∭ ρ(x² + y²) dV = ∭ ρ·r³ dz dr dθ

Đặt x = r cosθ, y = r sinθ, z = z
⇒ dV = r dz dr dθ
⇒ x² + y² = r²

• Mật độ ρ = 10.
• Miền: Xy lanh bán kính 4, cao 5.
• Ứng dụng: Tính toán chuyển động quay của vật rắn."""

create_problem_tab(notebook, "Bài 5 (Moment of Inertia)", compute_bai5, create_plot_bai5, bai5_explain)


# Nút Thoát (đặt ngoài notebook cho dễ thấy)
bottom_frame = ttk.Frame(root)
bottom_frame.pack(fill='x', pady=5)
ttk.Button(bottom_frame, text="❌ Thoát chương trình", command=root.quit).pack(side='right', padx=20)

root.mainloop()