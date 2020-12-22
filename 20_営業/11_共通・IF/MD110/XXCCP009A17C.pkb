CREATE OR REPLACE PACKAGE BODY APPS.XXCCP009A17C
AS
/*****************************************************************************************
 *
 * Package Name     : XXCCP009A17C(body)
 * Description      : OIF�p�[�W�@�\�iAP_AR_GL�j
 * Version          : 1.0
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- ------------------------------------------------------------
 *  submain                  ���C�������v���V�[�W��
 *  main                     �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *  ap_header                AP�w�b�_�[�v���V�[�W��
 *  ap_line                  AP���׃v���V�[�W��
 *  ar_header                AR�w�b�_�[�v���V�[�W��
 *  ar_line                  AR���׃v���V�[�W��
 *  gl_header                GL�w�b�_�[�v���V�[�W��
 *  gl_line                  GL���׃v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/12/10    1.0   SCSK�y���      �V�K�쐬
 *
 *****************************************************************************************/
--
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg         VARCHAR2(2000);
--
--################################  �Œ蕔 END   ##################################
--
--##########################  �Œ苤�ʗ�O�錾�� START  ###########################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
--################################  �Œ蕔 END   ##################################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  -- �p�b�P�[�W��
  cv_pkg_name               CONSTANT VARCHAR2(20)  := 'XXCCP009A17C';
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';        -- �A�h�I���F���ʁEIF�̈�
--
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'REQ_ID';            -- �v��ID���b�Z�[�W�p�g�[�N����
  cv_req_ap_header_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00029';  -- �폜�Ώۗv��ID���b�Z�[�W�iAP������̓w�b�_�j
  cv_req_ap_line_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00030';  -- �폜�Ώۗv��ID���b�Z�[�W�iAP������͖��ׁj
  cv_req_ar_header_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00031';  -- �폜�Ώۗv��ID���b�Z�[�W�iAR������̓w�b�_�j
  cv_req_ar_line_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00032';  -- �폜�Ώۗv��ID���b�Z�[�W�iAR������͖��ׁj
  cv_req_gl_header_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00033';  -- �폜�Ώۗv��ID���b�Z�[�W�iGL������̓w�b�_�j
  cv_req_gl_line_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00034';  -- �폜�Ώۗv��ID���b�Z�[�W�iGL������͖��ׁj
  -- �t�F�[�Y
  cv_phase_code_normal      CONSTANT VARCHAR2(30)  := 'C';         -- ����
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_ap_header_cnt   NUMBER;             -- AP�w�b�_�[�Ώی���
  gn_ap_line_cnt     NUMBER;             -- AP���בΏی���
  gn_ar_header_cnt   NUMBER;             -- AR�w�b�_�[�Ώی���
  gn_ar_line_cnt     NUMBER;             -- AR���בΏی���
  gn_gl_header_cnt   NUMBER;             -- GL�w�b�_�[�Ώی���
  gn_gl_line_cnt     NUMBER;             -- GL���בΏی���
  gn_error_cnt       NUMBER;             -- �G���[����
--
  --==================================================
  -- �O���[�o���J�[�\��
  --==================================================
--
  /**********************************************************************************
   * Procedure Name   : ap_header
   * Description      : AP�w�b�_�[�v���V�[�W��
   **********************************************************************************/
  PROCEDURE ap_header(
    ov_errbuf           OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'ap_header';   -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_request_id    xx03_payment_slips_if.request_id%TYPE; -- �v��ID
--
  --==================================================
  -- ���[�J���J�[�\��
  --==================================================
    -- AP�w�b�_�[
    CURSOR ap_header_cur
    IS
      SELECT DISTINCT xpsi.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- �R���J�����g���
             xx03_payment_slips_if xpsi                -- AP�w�b�_�[OIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- �t�F�[�Y
      AND    fcr.request_id  = xpsi.request_id
      ;
    ap_header_rec ap_header_cur%ROWTYPE;
--
    -- AP�w�b�_�[�i�r���j
    CURSOR ap_header_lock_cur(
      in_request_id IN NUMBER   -- 1.�v��ID
    ) IS
      SELECT xpsi.request_id request_id
      FROM   xx03_payment_slips_if xpsi                -- AP�w�b�_�[OIF
      WHERE  xpsi.request_id = in_request_id
      FOR UPDATE OF xpsi.request_id NOWAIT
      ;
    ap_header_lock_rec ap_header_lock_cur%ROWTYPE;
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***************************************
--
    BEGIN
        -- AP�w�b�_�[OIF
        FOR ap_header_rec IN ap_header_cur LOOP
--
          BEGIN
            -- �r������
            OPEN ap_header_lock_cur(
              ap_header_rec.request_id    -- 1.�v��ID
            );
            FETCH ap_header_lock_cur INTO ap_header_lock_rec;
            CLOSE ap_header_lock_cur;
--
            -- �폜����
            DELETE  xx03_payment_slips_if xpsi
              WHERE xpsi.request_id   = ap_header_rec.request_id
            ;
--
            --�����J�E���g
            gn_ap_header_cnt   := gn_ap_header_cnt + SQL%ROWCOUNT;
--
            --�폜�Ώ�ID�o��(AP�w�b�_�[)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_ap_header_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  ap_header_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( ap_header_lock_cur%ISOPEN ) THEN
                -- �J�[�\���̃N���[�Y
                CLOSE ap_header_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END ap_header;
--
  /**********************************************************************************
   * Procedure Name   : ap_line
   * Description      : AP���׃v���V�[�W��
   **********************************************************************************/
  PROCEDURE ap_line(
    ov_errbuf           OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'ap_line';   -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_request_id    xx03_payment_slip_lines_if.request_id%TYPE; -- �v��ID
--
  --==================================================
  -- ���[�J���J�[�\��
  --==================================================
    -- AP����
    CURSOR ap_line_cur
    IS
      SELECT DISTINCT xpsli.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- �R���J�����g���
             xx03_payment_slip_lines_if xpsli          -- AP����OIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- �t�F�[�Y
      AND    fcr.request_id  = xpsli.request_id
      ;
    ap_line_rec ap_line_cur%ROWTYPE;
--
    -- AP���ׁi�r���j
    CURSOR ap_line_lock_cur(
      in_request_id IN NUMBER   -- 1.�v��ID
    ) IS
      SELECT xpsli.request_id request_id
      FROM   xx03_payment_slip_lines_if xpsli          -- AP����OIF
      WHERE  xpsli.request_id = in_request_id
      FOR UPDATE OF xpsli.request_id NOWAIT
      ;
    ap_line_lock_rec ap_line_lock_cur%ROWTYPE;
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***************************************
--
    BEGIN
        -- AP����OIF
        FOR ap_line_rec IN ap_line_cur LOOP
--
          BEGIN
--
            -- �r������
            OPEN ap_line_lock_cur(
              ap_line_rec.request_id    -- 1.�v��ID
            );
            FETCH ap_line_lock_cur INTO ap_line_lock_rec;
            CLOSE ap_line_lock_cur;
--
            -- �폜����
            DELETE  xx03_payment_slip_lines_if xpsli
              WHERE xpsli.request_id   = ap_line_rec.request_id
            ;
--
            --�����J�E���g
            gn_ap_line_cnt   := gn_ap_line_cnt + SQL%ROWCOUNT;
--
            --�폜�Ώ�ID�o��(AP����)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_ap_line_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  ap_line_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( ap_line_lock_cur%ISOPEN ) THEN
                -- �J�[�\���̃N���[�Y
                CLOSE ap_line_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END ap_line;
--
  /**********************************************************************************
   * Procedure Name   : ar_header
   * Description      : AR�w�b�_�[�v���V�[�W��
   **********************************************************************************/
  PROCEDURE ar_header(
    ov_errbuf           OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'ar_header';   -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_request_id    xx03_receivable_slips_if.request_id%TYPE; -- �v��ID
--
  --==================================================
  -- ���[�J���J�[�\��
  --==================================================
    -- AR�w�b�_�[
    CURSOR ar_header_cur
    IS
      SELECT DISTINCT xrsi.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- �R���J�����g���
             xx03_receivable_slips_if xrsi             -- AR�w�b�_�[OIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- �t�F�[�Y
      AND    fcr.request_id  = xrsi.request_id
      ;
    ar_header_rec ar_header_cur%ROWTYPE;
--
    -- AR�w�b�_�[�i�r���j
    CURSOR ar_header_lock_cur(
      in_request_id IN NUMBER   -- 1.�v��ID
    ) IS
      SELECT xrsi.request_id request_id
      FROM   xx03_receivable_slips_if xrsi             -- AR�w�b�_�[OIF
      WHERE  xrsi.request_id = in_request_id
      FOR UPDATE OF xrsi.request_id NOWAIT
      ;
    ar_header_lock_rec ar_header_lock_cur%ROWTYPE;
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***************************************
--
    BEGIN
        -- AR�w�b�_�[OIF
        FOR ar_header_rec IN ar_header_cur LOOP
--
          BEGIN
            -- �r������
            OPEN ar_header_lock_cur(
              ar_header_rec.request_id    -- 1.�v��ID
            );
            FETCH ar_header_lock_cur INTO ar_header_lock_rec;
            CLOSE ar_header_lock_cur;
--
            -- �폜����
            DELETE  xx03_receivable_slips_if xrsi
              WHERE xrsi.request_id   = ar_header_rec.request_id
            ;
            --�����J�E���g
            gn_ar_header_cnt   := gn_ar_header_cnt + SQL%ROWCOUNT;
--
            --�폜�Ώ�ID�o��(AR�w�b�_�[)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_ar_header_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  ar_header_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( ar_header_lock_cur%ISOPEN ) THEN
                -- �J�[�\���̃N���[�Y
                CLOSE ar_header_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END ar_header;
--
  /**********************************************************************************
   * Procedure Name   : ar_line
   * Description      : AR���׃v���V�[�W��
   **********************************************************************************/
  PROCEDURE ar_line(
    ov_errbuf           OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'ar_line';   -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_request_id    xx03_receivable_slips_line_if.request_id%TYPE; -- �v��ID
--
  --==================================================
  -- ���[�J���J�[�\��
  --==================================================
    -- AR����
    CURSOR ar_line_cur
    IS
      SELECT DISTINCT xrsli.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- �R���J�����g���
             xx03_receivable_slips_line_if xrsli       -- AR����OIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- �t�F�[�Y
      AND    fcr.request_id  = xrsli.request_id
      ;
    ar_line_rec ar_line_cur%ROWTYPE;
--
    -- AR���ׁi�r���j
    CURSOR ar_line_lock_cur(
      in_request_id IN NUMBER   -- 1.�v��ID
    ) IS
      SELECT xrsli.request_id request_id
      FROM   xx03_receivable_slips_line_if xrsli       -- AR����OIF
      WHERE  xrsli.request_id = in_request_id
      FOR UPDATE OF xrsli.request_id NOWAIT
      ;
    ar_line_lock_rec ar_line_lock_cur%ROWTYPE;
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***************************************
--
    BEGIN
        -- AR����OIF
        FOR ar_line_rec IN ar_line_cur LOOP
--
          BEGIN
            -- �r������
            OPEN ar_line_lock_cur(
              ar_line_rec.request_id    -- 1.�v��ID
            );
            FETCH ar_line_lock_cur INTO ar_line_lock_rec;
            CLOSE ar_line_lock_cur;
--
            -- �폜����
            DELETE  xx03_receivable_slips_line_if xrsli
              WHERE xrsli.request_id   = ar_line_rec.request_id
            ;
            --�����J�E���g
            gn_ar_line_cnt   := gn_ar_line_cnt + SQL%ROWCOUNT;
--
            --�폜�Ώ�ID�o��(AR����)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_ar_line_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  ar_line_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( ar_line_lock_cur%ISOPEN ) THEN
                -- �J�[�\���̃N���[�Y
                CLOSE ar_line_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END ar_line;
--
  /**********************************************************************************
   * Procedure Name   : gl_header
   * Description      : GL�w�b�_�[�v���V�[�W��
   **********************************************************************************/
  PROCEDURE gl_header(
    ov_errbuf           OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'gl_header';   -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_request_id    xx03_journal_slips_if.request_id%TYPE; -- �v��ID
--
  --==================================================
  -- ���[�J���J�[�\��
  --==================================================
    -- GL�w�b�_�[
    CURSOR gl_header_cur
    IS
      SELECT DISTINCT xjsi.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- �R���J�����g���
             xx03_journal_slips_if xjsi                -- GL�w�b�_�[OIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- �t�F�[�Y
      AND    fcr.request_id  = xjsi.request_id
      ;
    gl_header_rec gl_header_cur%ROWTYPE;
--
    -- GL�w�b�_�[�i�r���j
    CURSOR gl_header_lock_cur(
      in_request_id IN NUMBER   -- 1.�v��ID
    ) IS
      SELECT xjsi.request_id request_id
      FROM   xx03_journal_slips_if xjsi                -- GL�w�b�_�[OIF
      WHERE  xjsi.request_id = in_request_id
      FOR UPDATE OF xjsi.request_id NOWAIT
      ;
    gl_header_lock_rec gl_header_lock_cur%ROWTYPE;
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***************************************
--
    BEGIN
        -- GL�w�b�_�[OIF
        FOR gl_header_rec IN gl_header_cur LOOP
--
          BEGIN
            -- �r������
            OPEN gl_header_lock_cur(
              gl_header_rec.request_id    -- 1.�v��ID
            );
            FETCH gl_header_lock_cur INTO gl_header_lock_rec;
            CLOSE gl_header_lock_cur;
--
            -- �폜����
            DELETE  xx03_journal_slips_if xjsi
              WHERE xjsi.request_id   = gl_header_rec.request_id
            ;
            --�����J�E���g
            gn_gl_header_cnt   := gn_gl_header_cnt + SQL%ROWCOUNT;
--
            --�폜�Ώ�ID�o��(GL�w�b�_�[)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_gl_header_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  gl_header_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( gl_header_lock_cur%ISOPEN ) THEN
                -- �J�[�\���̃N���[�Y
                CLOSE gl_header_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END gl_header;
--
  /**********************************************************************************
   * Procedure Name   : gl_line
   * Description      : GL���׃v���V�[�W��
   **********************************************************************************/
  PROCEDURE gl_line(
    ov_errbuf           OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'gl_line';   -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
    ln_request_id    xx03_journal_slip_lines_if.request_id%TYPE; -- �v��ID
--
  --==================================================
  -- ���[�J���J�[�\��
  --==================================================
    -- GL����
    CURSOR gl_line_cur
    IS
      SELECT DISTINCT xjsli.request_id request_id
      FROM   applsys.fnd_concurrent_requests fcr,      -- �R���J�����g���
             xx03_journal_slip_lines_if xjsli          -- GL����OIF
      WHERE  fcr.phase_code  = cv_phase_code_normal    -- �t�F�[�Y
      AND    fcr.request_id  = xjsli.request_id
      ;
    gl_line_rec gl_line_cur%ROWTYPE;
--
    -- GL���ׁi�r���j
    CURSOR gl_line_lock_cur(
      in_request_id IN NUMBER   -- 1.�v��ID
    ) IS
      SELECT xjsli.request_id request_id
      FROM   xx03_journal_slip_lines_if xjsli          -- GL����OIF
      WHERE  xjsli.request_id = in_request_id
      FOR UPDATE OF xjsli.request_id NOWAIT
      ;
    gl_line_lock_rec gl_line_lock_cur%ROWTYPE;

--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***************************************
--
    BEGIN
        -- GL����OIF
        FOR gl_line_rec IN gl_line_cur LOOP
--
          BEGIN
            -- �r������
            OPEN gl_line_lock_cur(
              gl_line_rec.request_id    -- 1.�v��ID
            );
            FETCH gl_line_lock_cur INTO gl_line_lock_rec;
            CLOSE gl_line_lock_cur;
--
            -- �폜����
            DELETE  xx03_journal_slip_lines_if xjsli
              WHERE xjsli.request_id   = gl_line_rec.request_id
            ;
            --�����J�E���g
            gn_gl_line_cnt   := gn_gl_line_cnt + SQL%ROWCOUNT;
--
            --�폜�Ώ�ID�o��(GL����)
            gv_out_msg := xxccp_common_pkg.get_msg(
                             iv_application  => cv_appl_short_name
                            ,iv_name         => cv_req_gl_line_msg
                            ,iv_token_name1  => cv_cnt_token
                            ,iv_token_value1 => TO_CHAR(  gl_line_rec.request_id )
                           );
            FND_FILE.PUT_LINE(
               which  => FND_FILE.LOG
              ,buff   => gv_out_msg
            );
--
            COMMIT;
--
          EXCEPTION
            WHEN OTHERS THEN
              IF ( gl_line_lock_cur%ISOPEN ) THEN
                -- �J�[�\���̃N���[�Y
                CLOSE gl_line_lock_cur;
              END IF;
--
              ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
              ov_retcode := cv_status_error;
              gn_error_cnt := gn_error_cnt + 1;
              ROLLBACK;
          END;
--
        END LOOP;
--
    END;
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END gl_line;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf           OUT    VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode          OUT    VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg           OUT    VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';   -- �v���O������
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf        VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode       VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg        VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  --==================================================
  -- ���[�J���J�[�\��
  --==================================================
--
--
--###########################  �Œ蕔 END   ####################################
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***************************************
--
    BEGIN
      -- AP�w�b�_�[OIF
      ap_header(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --�G���[���b�Z�[�W
        );
      END IF;
--
      -- AP����OIF
      ap_line(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --�G���[���b�Z�[�W
        );
      END IF;
--
      -- AR�w�b�_�[OIF
      ar_header(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --�G���[���b�Z�[�W
        );
      END IF;
--
      -- AR����OIF
      ar_line(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --�G���[���b�Z�[�W
        );
      END IF;
--
      -- GL�w�b�_�[OIF
      gl_header(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --�G���[���b�Z�[�W
        );
      END IF;
--
      -- GL����OIF
      gl_line(
         lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
        ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
        ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        FND_FILE.PUT_LINE(
           which  => FND_FILE.LOG
          ,buff   => lv_errbuf --�G���[���b�Z�[�W
        );
      END IF;
--
    END;
--
--
  EXCEPTION
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,       --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode             OUT    VARCHAR2        --   ���^�[���E�R�[�h    --# �Œ� #
  )
--
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_cnt_token         CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    cv_del_ap_header_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00023'; -- �폜�������b�Z�[�W�iXX03_PAYMENT_SLIPS_IF�j
    cv_del_ap_line_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00024'; -- �폜�������b�Z�[�W�iXX03_PAYMENT_SLIP_LINES_IF�j
    cv_del_ar_header_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00025'; -- �폜�������b�Z�[�W�iXX03_RECEIVABLE_SLIPS_IF�j
    cv_del_ar_line_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00026'; -- �폜�������b�Z�[�W�iXX03_RECEIVABLE_SLIPS_LINE_IF�j
    cv_del_gl_header_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00027'; -- �폜�������b�Z�[�W�iXX03_JOURNAL_SLIPS_IF�j
    cv_del_gl_line_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00028'; -- �폜�������b�Z�[�W�iXX03_JOURNAL_SLIP_LINES_IF�j
    cv_error_rec_msg     CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_normal_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_msg_err_end       CONSTANT VARCHAR2(100) := '�������G���[�I�����܂����B';     -- �G���[�I�����b�Z�[�W
--
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    --
  BEGIN
--
    -- ===============================================
    -- ��������
    -- ===============================================
    --
    -- 1.�ϐ�������
    gn_ap_header_cnt := 0;
    gn_ap_line_cnt   := 0;
    gn_ar_header_cnt := 0;
    gn_ar_line_cnt   := 0;
    gn_gl_header_cnt := 0;
    gn_gl_line_cnt   := 0;
    gn_error_cnt     := 0;
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       lv_errbuf   -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode  -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg   -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�Ώی����o��(AP�w�b�_�[)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_ap_header_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_ap_header_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o��(AP����)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_ap_line_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_ap_line_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o��(AR�w�b�_�[)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_ar_header_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_ar_header_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o��(AR����)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_ar_line_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_ar_line_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o��(GL�w�b�_�[)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_gl_header_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_gl_header_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�Ώی����o��(GL����)
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_del_gl_line_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_gl_line_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    -- ����
    IF ( gn_error_cnt = 0
      AND ( gn_ap_header_cnt + gn_ap_line_cnt + gn_ar_header_cnt + gn_ar_line_cnt + gn_gl_header_cnt + gn_gl_line_cnt > 0 ) ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_normal_msg
                     );
      lv_retcode := cv_status_normal;
    -- �x��
    ELSIF ( gn_error_cnt = 0
      AND ( gn_ap_header_cnt + gn_ap_line_cnt + gn_ar_header_cnt + gn_ar_line_cnt + gn_gl_header_cnt + gn_gl_line_cnt = 0 ) ) THEN
      gv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_warn_msg
                     );
      lv_retcode := cv_status_warn;
    -- �ُ�
    ELSIF( gn_error_cnt > 0 ) THEN
      gv_out_msg := cv_msg_err_end;
      lv_retcode := cv_status_error;
      ROLLBACK;
    END IF;
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END XXCCP009A17C;
/
