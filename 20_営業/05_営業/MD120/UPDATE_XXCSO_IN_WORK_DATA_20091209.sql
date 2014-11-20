DECLARE
-----------------------------------------------------------------------------------------
-- XXCSO_IN_WORK_DATA �̊����f�[�^���ȉ��̒ʂ�X�V���܂��B
-- infos_interface_flag : 'Y'
-- infos_interface_date : TRUNC(last_update_date)
-----------------------------------------------------------------------------------------
--
  -- ===============================
  -- ���[�J���萔
  -- ===============================
  cv_yes             CONSTANT VARCHAR2(1) := 'Y';
  -- ===============================
  -- ���[�J���ϐ�
  -- ===============================
  ln_target_cnt      NUMBER DEFAULT 0;     -- �����Ώی���
  ln_normal_cnt      NUMBER DEFAULT 0;     -- ��������
  -- ===============================
  -- ���[�J���J�[�\��
  -- ===============================
  CURSOR get_data_cur
  IS
    SELECT  xiwd.seq_no                     seq_no             -- �V�[�P���X�ԍ�
           ,TRUNC(xiwd.last_update_date)    last_update_date   -- �ŏI�X�V��
    FROM   xxcso.xxcso_in_work_data  xiwd                         -- ��ƃf�[�^�e�[�u��
    ORDER BY xiwd.seq_no;
  -- ===============================
  -- ���[�J�����R�[�h
  -- ===============================
  l_get_data_rec      get_data_cur%ROWTYPE  DEFAULT NULL;
--
BEGIN
--
    OPEN get_data_cur;
--
    <<get_data_loop>>
    LOOP
      BEGIN
        FETCH get_data_cur INTO l_get_data_rec;
        -- �����Ώی����i�[
        ln_target_cnt := get_data_cur%ROWCOUNT;
--
        EXIT WHEN get_data_cur%NOTFOUND
        OR  get_data_cur%ROWCOUNT = 0;
--
        --�X�V����
        UPDATE xxcso.xxcso_in_work_data
        SET    infos_interface_flag  =  cv_yes                           -- ���n�A�g�σt���O
              ,infos_interface_date  =  l_get_data_rec.last_update_date  -- ���n�A�g��
        WHERE  seq_no = l_get_data_rec.seq_no;
--
        --���������J�E���g
        ln_normal_cnt := ln_normal_cnt + 1;
--
      EXCEPTION
        WHEN OTHERS THEN
          -- �J�[�\���N���[�Y
          CLOSE get_data_cur;
--
          dbms_output.put_line('* * update_error * *');
          dbms_output.put_line('ln_target_cnt : ' || ln_target_cnt );
          dbms_output.put_line('ln_normal_cnt : ' || ln_normal_cnt );
          ROLLBACK;
      END;
    END LOOP get_data_loop;
    -- �J�[�\���N���[�Y
    CLOSE get_data_cur;
--
  -- ���b�Z�[�W�o��
  dbms_output.put_line('* * update_succeed * *');
  dbms_output.put_line('ln_target_cnt : ' || ln_target_cnt );
  dbms_output.put_line('ln_normal_cnt : ' || ln_normal_cnt );
--
EXCEPTION
  WHEN OTHERS THEN
    -- �J�[�\���N���[�Y
    CLOSE get_data_cur;
--
    dbms_output.put_line('* * update_error * *');
    dbms_output.put_line('ln_target_cnt : ' || ln_target_cnt );
    dbms_output.put_line('ln_normal_cnt : ' || ln_normal_cnt );
    ROLLBACK;
END;
/
