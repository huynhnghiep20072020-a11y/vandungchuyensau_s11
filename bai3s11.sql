DELIMITER //

CREATE PROCEDURE CalculateHospitalFee(
    IN p_total_cost DECIMAL(18,2),
    IN p_patient_type VARCHAR(20),
    OUT p_final_fee DECIMAL(18,2),
    OUT p_status_message VARCHAR(255)
)
BEGIN
    -- Bước 1: Kiểm tra dữ liệu đầu vào không hợp lệ
    IF p_total_cost < 0 THEN
        SET p_final_fee = 0;
        SET p_status_message = 'Lỗi: Chi phí không hợp lệ';
    ELSE
        -- Bước 2: Tính toán dựa trên diện bệnh nhân
        IF p_patient_type = 'BHYT' THEN
            SET p_final_fee = p_total_cost * 0.2; -- Bệnh nhân đóng 20%
        ELSEIF p_patient_type = 'VIP' THEN
            SET p_final_fee = p_total_cost * 0.9; -- Giảm giá 10%
        ELSEIF p_patient_type = 'THUONG' THEN
            SET p_final_fee = p_total_cost;      -- Đóng 100%
        ELSE
            -- Trường hợp nhập sai loại bệnh nhân, tính giá gốc để tránh thất thoát
            SET p_final_fee = p_total_cost;
        END IF;
        
        -- Bước 3: Thông báo thành công
        SET p_status_message = 'Đã tính toán xong';
    END IF;
END //

DELIMITER ;

--  Kiểm thử hệ thống (Test Cases)
-- Trường hợp 1: Bệnh nhân BHYT (Chi phí 1,000,000 -> Phải đóng 200,000)
CALL CalculateHospitalFee(1000000, 'BHYT', @fee1, @msg1);
SELECT @fee1 AS Amount, @msg1 AS Message;

-- Trường hợp 2: Bệnh nhân VIP (Chi phí 1,000,000 -> Phải đóng 900,000)
CALL CalculateHospitalFee(1000000, 'VIP', @fee2, @msg2);
SELECT @fee2 AS Amount, @msg2 AS Message;

-- Trường hợp 3: Bệnh nhân THUONG (Chi phí 1,000,000 -> Phải đóng 1,000,000)
CALL CalculateHospitalFee(1000000, 'THUONG', @fee3, @msg3);
SELECT @fee3 AS Amount, @msg3 AS Message;

-- Trường hợp 4: Chặn lỗi chi phí âm (Bẫy dữ liệu)
CALL CalculateHospitalFee(-500000, 'BHYT', @fee4, @msg4);
SELECT @fee4 AS Amount, @msg4 AS Message;