create or replace
PACKAGE BODY XXCFF004A28C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF004A28C(body)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �ă��[�X�v�ۃ_�E�����[�h 004_A28
 * Version          : 1.3
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  para_check             p �p�����[�^�`�F�b�N����                  (A-2)
 *  csv_buf                p CSV�ҏW����                             (A-4)
 *  csv_header             p CSV�w�b�_�[�쐬
 *  submain                p ���C�������v���V�[�W��
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/05    1.0   SCS��� �M�K     �V�K�쐬
 *  2009/02/09    1.1   SCS��� �M�K     ���O�o�͍��ڒǉ�
 *  2009/08/11    1.2   SCS���� �L��     �����e�X�g��Q0000994�Ή�
 *  2018/09/18    1.3   SCSK���X�ؑ�a   E_�{�ғ�_14830�̂���
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- �Ώی���
  gn_normal_cnt    NUMBER;                    -- ���팏��
  gn_error_cnt     NUMBER;                    -- �G���[����
  gn_warn_cnt      NUMBER;                    -- �X�L�b�v����
  gv_process_date  VARCHAR2(30);              --�����^�Ɩ����t
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
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  �Œ蕔 END   ##################################
---- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--  <exception_name>          EXCEPTION;     -- <��O�̃R�����g>
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFF004A28C';      -- �p�b�P�[�W��
  cv_log             CONSTANT VARCHAR2(100) := 'LOG';               -- �R���J�����g���O�o�͐�--
--
  cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCFF';             -- �A�h�I���F��v�E���[�X�EFA�̈�
  cv_appl_name_cmn   CONSTANT VARCHAR2(10)  := 'XXCCP';             -- �A�h�I���F���ʁEIF�̈�
  cv_para_err_msg    CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00003';  -- �p�����[�^�t�]�G���[���b�Z�[�W
  cv_no_data_msg     CONSTANT VARCHAR2(100) := 'APP-XXCFF1-00062';  -- �ΏۂȂ��x�����b�Z�[�W
--
  cv_para_from_tkn   CONSTANT VARCHAR2(100)  := 'FROM';             -- �p�����[�^FROM�g�[�N��
  cv_para_to_tkn     CONSTANT VARCHAR2(100)  := 'TO';               -- �p�����[�^TO�g�[�N��
  cv_csv_delim       CONSTANT VARCHAR2(3)    := ',';                -- CSV��؂蕶��
  cv_look_type       CONSTANT VARCHAR2(100)  := 'XXCFF1_RE_LEASE_CSV_HEADER'; -- LOOKUP TYPE
  cv_date_format     CONSTANT VARCHAR2(100)  := 'YYYY/MM/DD';       -- ���t�t�H�[�}�b�g
  cv_money_format    CONSTANT VARCHAR2(100)  := 'FM999,999,990';    -- ���z�t�H�[�}�b�g
  cv_obj_status_102  CONSTANT VARCHAR2(100)  := '102';              -- �_���
  cv_obj_status_104  CONSTANT VARCHAR2(100)  := '104';              -- �ă��[�X�_���
  cv_obj_status_108  CONSTANT VARCHAR2(100)  := '108';              -- ���\��
  cv_class_min       CONSTANT VARCHAR2(100)  := '00';               -- ���[�X��ʍŏ��l
-- 1.3 2018/09/18 Modified START
--cv_class_max       CONSTANT VARCHAR2(100)  := '99';               -- ���[�X��ʍő�l
  cv_class_max       CONSTANT VARCHAR2(100)  := 'ZZ';               -- ���[�X��ʍő�l
-- 1.3 2018/09/18 Modified END
  cv_csv_data_type   CONSTANT VARCHAR2(100)  := '"1"';              -- CSV�f�[�^�敪�l
  cv_wqt             CONSTANT VARCHAR2(100)  := '"';                -- CSV�����f�[�^�͂�����
--
  cv_tkn_val1        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50104'; -- ���[�X�I����From
  cv_tkn_val2        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50105'; -- ���[�X�I����To
  cv_tkn_val3        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50101'; -- ���[�X���From
  cv_tkn_val4        CONSTANT VARCHAR2(100)  := 'APP-XXCFF1-50100'; -- ���[�X���To
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
    CURSOR get_release_cur(in_date_from  DATE
                          ,in_date_to    DATE
                          ,in_class_from VARCHAR2
                          ,in_class_to   VARCHAR2)
    IS
    SELECT
       xoh.lease_class                as lease_class               --���[�X���
      ,xoh.re_lease_flag              as re_lease_flag             --�ă��[�X�v��
      ,xoh.lease_type                 as lease_type                --���[�X�敪
      ,xoh.re_lease_times             as re_lease_times            --�ă��[�X��
      ,xoh.object_code                as object_code               --�����R�[�h
      ,xoh.object_status              as object_status             --�����X�e�[�^�X�R�[�h
      ,xoh.department_code            as department_code           --�Ǘ�����R�[�h
      ,xoh.po_number                  as po_number                 --�����ԍ�
      ,xoh.manufacturer_name          as manufacturer_name         --���[�J�[��
      ,xoh.age_type                   as age_type                  --�N��
      ,xoh.model                      as model                     --�@��
      ,xoh.serial_number              as serial_number             --�@��
      ,xoh.quantity                   as quantity                  --����
      ,xoh.chassis_number             as chassis_number            --�ԑ�ԍ�
      ,xch.contract_number            as contract_number           --�_��ԍ�
      ,xch.lease_company              as lease_company             --���[�X��ЃR�[�h
      ,xch.payment_frequency          as payment_frequency         --�x����
      ,xch.lease_start_date           as lease_start_date          --���[�X�J�n��
      ,xch.lease_end_date             as lease_end_date            --���[�X�I����
      ,xcl.contract_line_num          as contract_line_num         --�_��}��
      ,xcl.second_total_charge        as second_total_charge       --���z���[�X��(�ō�)
      ,xcl.estimated_cash_price       as estimated_cash_price      --���ό����w�����z
      ,xcl.second_charge              as second_charge             --���z���[�X��(�Ŕ�)
      ,xcl.second_total_deduction     as second_total_deduction    --���z���[�X�T���z
      ,xcl.first_installation_address as first_installation_address--����ݒu�ꏊ
      ,xcl.first_installation_place   as first_installation_place  --����ݒu��
      ,xlcv.lease_company_name        as lease_company_name        --���[�X��Ж�
      ,xdv.department_name            as department_name           --�Ǘ����喼
      ,xosv.object_status_name        as object_status_name        --�����X�e�[�^�X��
-- 0000994 2009/08/11 ADD START
      ,xch.comments                   as comments                  --����
-- 0000994 2009/08/11 ADD END     
    FROM
       xxcff_object_headers   xoh
      ,xxcff_contract_headers xch
      ,xxcff_contract_lines   xcl
      ,xxcff_lease_company_v  xlcv
      ,xxcff_department_v     xdv
      ,xxcff_object_status_v  xosv
    WHERE
        xch.contract_header_id = xcl.contract_header_id
    AND xcl.object_header_id   = xoh.object_header_id
    AND xch.re_lease_times     = xoh.re_lease_times
    AND xch.lease_class       >= NVL(in_class_from, cv_class_min) --�p�����[�^�D���[�X��ʃR�[�hFrom
    AND xch.lease_class       <= NVL(in_class_to, cv_class_max)   --�p�����[�^�D���[�X��ʃR�[�hTo
    AND xch.lease_end_date    >= in_date_from  --�p�����[�^�D���[�X�I����From
    AND xch.lease_end_date    <= in_date_to    --�p�����[�^�D���[�X�I����To
    AND xch.lease_company      = xlcv.lease_company_code(+)
    AND xoh.department_code    = xdv.department_code(+)
    AND xoh.object_status      = xosv.object_status_code(+)
    AND xoh.object_status     IN (cv_obj_status_102, cv_obj_status_104, cv_obj_status_108)
    ORDER BY
        xoh.department_code
       ,xch.lease_company
       ,xch.contract_number
       ,xcl.contract_line_num;
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : para_check
   * Description      : �p�����[�^�`�F�b�N����(A-2)
   ***********************************************************************************/
  PROCEDURE para_check(
    id_date_from  IN  DATE,                --   1.���[�X�I����FROM
    id_date_to    IN  DATE,                --   2.���[�X�I����TO
    iv_class_from IN  VARCHAR2,            --   3.���[�X���FROM
    iv_class_to   IN  VARCHAR2,            --   4.���[�X���TO
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'para_check'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
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
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
--    ���[�X�I�����̃p�����[�^�`�F�b�N
    IF (id_date_from > id_date_to) THEN
      lv_errbuf := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_para_err_msg,
                                            cv_para_from_tkn,   cv_tkn_val1,
                                            cv_para_to_tkn,     cv_tkn_val2);
      RAISE global_api_expt;
    END IF;
--    ���[�X��ʂ̃p�����[�^�`�F�b�N FROM,TO�����w��̏ꍇ
    IF (  (iv_class_from IS NOT NULL)
      AND (iv_class_to IS NOT NULL)) THEN
      IF (iv_class_from > iv_class_to) THEN
        lv_errbuf := xxccp_common_pkg.get_msg(cv_appl_short_name, cv_para_err_msg,
                                            cv_para_from_tkn,   cv_tkn_val3,
                                            cv_para_to_tkn,     cv_tkn_val4);
        RAISE global_api_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END para_check;
--
  /**********************************************************************************
   * Procedure Name   : csv_buf
   * Description      : CSV�ҏW����(A-4)
   ***********************************************************************************/
  PROCEDURE csv_buf(
    ir_release    IN  get_release_cur%ROWTYPE,            --  �ă��[�X�v�ۃ��R�[�h
    ov_csvbuf     OUT NOCOPY VARCHAR2,                    --  �쐬CSV�f�[�^
    ov_errbuf     OUT NOCOPY VARCHAR2,                    --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,                    --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)                    --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'csv_buf'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    ov_csvbuf := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    --�f�[�^�敪
    ov_csvbuf := ov_csvbuf ||           cv_csv_data_type                                              || cv_csv_delim;
    --�����R�[�h
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.object_code                              || cv_wqt || cv_csv_delim;
    --�ă��[�X�v��
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.re_lease_flag                            || cv_wqt || cv_csv_delim;
    --�_��ԍ�
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.contract_number                          || cv_wqt || cv_csv_delim;
    --�_��}��
    ov_csvbuf := ov_csvbuf ||           ir_release.contract_line_num                                  || cv_csv_delim;
    --�쐬���t
    ov_csvbuf := ov_csvbuf || cv_wqt || gv_process_date                                     || cv_wqt || cv_csv_delim;
    --�����X�e�[�^�X�R�[�h
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.object_status                            || cv_wqt || cv_csv_delim;
    --�����X�e�[�^�X��
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.object_status_name                       || cv_wqt || cv_csv_delim;
    --�Ǘ�����R�[�h
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.department_code                          || cv_wqt || cv_csv_delim;
    --�Ǘ����喼
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.department_name                          || cv_wqt || cv_csv_delim;
    --���[�X���
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.lease_class                              || cv_wqt || cv_csv_delim;
    --���[�X�敪
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.lease_type                               || cv_wqt || cv_csv_delim;
    --�ă��[�X��
    ov_csvbuf := ov_csvbuf ||           ir_release.re_lease_times                                     || cv_csv_delim;
    --���[�X��ЃR�[�h
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.lease_company                            || cv_wqt || cv_csv_delim;
    --���[�X��Ж�
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.lease_company_name                       || cv_wqt || cv_csv_delim;
    --�x����
    ov_csvbuf := ov_csvbuf ||           ir_release.payment_frequency                                  || cv_csv_delim;
    --���[�X�J�n��
    ov_csvbuf := ov_csvbuf || cv_wqt || TO_CHAR(ir_release.lease_start_date,cv_date_format) || cv_wqt || cv_csv_delim;
    --���[�X�I����
    ov_csvbuf := ov_csvbuf || cv_wqt || TO_CHAR(ir_release.lease_end_date,cv_date_format)   || cv_wqt || cv_csv_delim;
    --����ݒu�ꏊ
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.first_installation_address               || cv_wqt || cv_csv_delim;
    --����ݒu��
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.first_installation_place                 || cv_wqt || cv_csv_delim;
    --���ό����w�����z
    ov_csvbuf := ov_csvbuf ||           ir_release.estimated_cash_price                               || cv_csv_delim;
    --���z���[�X���i�Ŕ��j
    ov_csvbuf := ov_csvbuf ||           ir_release.second_charge                                      || cv_csv_delim;
    --���z���[�X���i�ō��j
    ov_csvbuf := ov_csvbuf ||           ir_release.second_total_charge                                || cv_csv_delim;
    --���z�T���z�i�ō��j
    ov_csvbuf := ov_csvbuf ||           ir_release.second_total_deduction                             || cv_csv_delim;
    --�����ԍ�
    ov_csvbuf := ov_csvbuf ||           ir_release.po_number                                          || cv_csv_delim;
    --���[�J�[��(�����Җ�)
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.manufacturer_name                        || cv_wqt || cv_csv_delim;
    --�N��
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.age_type                                 || cv_wqt || cv_csv_delim;
    --�@��
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.model                                    || cv_wqt || cv_csv_delim;
    --�@��
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.serial_number                            || cv_wqt || cv_csv_delim;
    --����
    ov_csvbuf := ov_csvbuf ||           ir_release.quantity                                           || cv_csv_delim;
    --�ԑ�ԍ�
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.chassis_number                           || cv_wqt || cv_csv_delim;
-- 0000994 2009/08/11 ADD START
    --����
    ov_csvbuf := ov_csvbuf || cv_wqt || ir_release.comments                                 || cv_wqt || cv_csv_delim;
-- 0000994 2009/08/11 ADD END    
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END csv_buf;
--
  /**********************************************************************************
   * Procedure Name   : csv_header
   * Description      : CSV�w�b�_�[�쐬
   ***********************************************************************************/
  PROCEDURE csv_header(
    ov_csvbuf     OUT NOCOPY VARCHAR2,                    --  �쐬CSV�w�b�_�[
    ov_errbuf     OUT NOCOPY VARCHAR2,                    --  �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,                    --  ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)                    --  ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'csv_header'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR csv_header_cur(in_type VARCHAR2)
    IS
    SELECT
           flv.lookup_code           AS lookup_code
          ,flv.description           AS item_name
    FROM   fnd_lookup_values_vl flv
    WHERE  lookup_type = in_type
    ORDER BY flv.meaning;
--
    -- *** ���[�J���E���R�[�h ***
    csv_header_cur_rec csv_header_cur%ROWTYPE;
--
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
    ov_csvbuf := NULL;
--
--###########################  �Œ蕔 END   ############################
--
    -- ***************************************
    -- ***        �������̋L�q             ***
    -- ***       ���ʊ֐��̌Ăяo��        ***
    -- ***************************************
    OPEN csv_header_cur(cv_look_type);
    LOOP
      FETCH csv_header_cur INTO csv_header_cur_rec;
      EXIT WHEN csv_header_cur%NOTFOUND;
      -- �w�b�_�[�s���쐬����B
      ov_csvbuf := ov_csvbuf || cv_wqt || csv_header_cur_rec.item_name || cv_wqt || cv_csv_delim;
    END LOOP;
    CLOSE csv_header_cur;

--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (csv_header_cur%ISOPEN) THEN
        CLOSE csv_header_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END csv_header;
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    iv_date_from  IN  VARCHAR2,            --   1.���[�X�I����FROM
    iv_date_to    IN  VARCHAR2,            --   2.���[�X�I����TO
    iv_class_from IN  VARCHAR2,            --   3.���[�X���FROM
    iv_class_to   IN  VARCHAR2,            --   4.���[�X���TO
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2)     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain'; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode  VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg   VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    ld_date_from DATE;           -- ���[�X�I����FROM
    ld_date_to   DATE;           -- ���[�X�I����TO
    lv_csvbuf   VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
--    lv_csvbuf   VARCHAR2(300);  -- �G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
--
    -- ===============================
    -- ���[�J���E�J�[�\��
    -- ===============================
    -- <�J�[�\����>

    -- <�J�[�\����>���R�[�h�^
    get_release_cur_rec           get_release_cur%ROWTYPE;
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- �O���[�o���ϐ��̏�����
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date, cv_date_format);
--
    --*********************************************
    --***      MD.050�̃t���[�}��\��           ***
    --***      ����Ə������̌Ăяo�����s��     ***
    --*********************************************
    -- =====================================================
    --  �p�����[�^�`�F�b�N����(A-2)
    -- =====================================================
--
    ld_date_from := TO_DATE(SUBSTR(iv_date_from, 1, 10), cv_date_format);
    ld_date_to   := TO_DATE(SUBSTR(iv_date_to, 1, 10), cv_date_format);
    para_check(
       id_date_from  => ld_date_from            --   1.���[�X�I����FROM
      ,id_date_to    => ld_date_to              --   2.���[�X�I����TO
      ,iv_class_from => iv_class_from           --   3.���[�X���FROM
      ,iv_class_to   => iv_class_to             --   4.���[�X���TO
      ,ov_retcode    => lv_retcode
      ,ov_errbuf     => lv_errbuf
      ,ov_errmsg     => lv_errmsg
    );
    IF (lv_retcode = cv_status_error) THEN
      --(�G���[����)
      RAISE global_process_expt;
    END IF;
    -- =====================================================
    --  �ă��[�X�v�ے��o����(A-3)
    -- =====================================================
    OPEN get_release_cur(ld_date_from, ld_date_to, iv_class_from, iv_class_to);
    LOOP
      FETCH get_release_cur INTO get_release_cur_rec;
      EXIT WHEN get_release_cur%NOTFOUND;
      gn_target_cnt := gn_target_cnt + 1;
      -- 1�s�ڂɂ̓w�b�_�[�s���o�͂���B
      IF (gn_target_cnt = 1) THEN
        csv_header(ov_csvbuf     => lv_csvbuf
                  ,ov_retcode    => lv_retcode
                  ,ov_errbuf     => lv_errbuf
                  ,ov_errmsg     => lv_errmsg
        );
        IF (lv_retcode = cv_status_error) THEN
        -- �W�����O�ɏo�͂���B
          FND_FILE.PUT_LINE(
            which  => FND_FILE.LOG
           ,buff   => lv_errbuf
          );
        ELSE
        -- �W���o�͂ɏo�͂���B
          FND_FILE.PUT_LINE(
            which  => FND_FILE.OUTPUT
           ,buff   => lv_csvbuf
          );
        END IF;
      END IF;
      -- =====================================================
      --  CSV�ҏW����(A-4)
      -- =====================================================
      csv_buf(get_release_cur_rec
             ,ov_csvbuf     => lv_csvbuf
             ,ov_retcode    => lv_retcode
             ,ov_errbuf     => lv_errbuf
             ,ov_errmsg     => lv_errmsg
      );
      IF (lv_retcode = cv_status_error) THEN
        gn_error_cnt := gn_error_cnt + 1;
        RAISE global_process_expt;
      ELSE
        -- �W���o�͂ɏo�͂���B
        FND_FILE.PUT_LINE(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_csvbuf
        );
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
    END LOOP;
    CLOSE get_release_cur;
    --�Ώی�����0�̏ꍇ�x���I���Ƃ���B
    --�Ώۃ��b�Z�[�W���o�͂���B
    IF (gn_target_cnt = 0) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => xxccp_common_pkg.get_msg(cv_appl_short_name, cv_no_data_msg) --�G���[���b�Z�[�W
      );
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** �C�ӂŗ�O�������L�q���� ****
      -- �J�[�\���̃N���[�Y�������ɋL�q����
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (get_release_cur%ISOPEN) THEN
        CLOSE get_release_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT NOCOPY   VARCHAR2,   --   �G���[���b�Z�[�W #�Œ�#
    retcode        OUT NOCOPY   VARCHAR2,   --   �G���[�R�[�h     #�Œ�#
    iv_date_from   IN  VARCHAR2,            --   1.���[�X�I����FROM
    iv_date_to     IN  VARCHAR2,            --   2.���[�X�I����TO
    iv_class_from  IN  VARCHAR2,            --   3.���[�X���FROM
    iv_class_to    IN  VARCHAR2             --   4.���[�X���TO
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- �v���O������
--
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- �Ώی������b�Z�[�W
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- �����������b�Z�[�W
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- �G���[�������b�Z�[�W
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- �X�L�b�v�������b�Z�[�W
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- ����I�����b�Z�[�W
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- �x���I�����b�Z�[�W
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- �G���[�I���S���[���o�b�N
--
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- �������b�Z�[�W�p�g�[�N����
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode         VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg          VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
    lv_message_code    VARCHAR2(100);   -- �I�����b�Z�[�W�R�[�h
    --
  BEGIN
--
--###########################  �Œ蕔 START   #####################################################
--
    -- �Œ�o��
    -- �R���J�����g�w�b�_���b�Z�[�W�o�͊֐��̌Ăяo��
    -- V1.1�p�Ή�  FROM
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
      ,iv_which   => cv_log
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    -- V1.1�p�Ή�  
    --
    xxcff_common1_pkg.put_log_param(
       ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
      ,iv_which   => cv_log
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
       iv_date_from   --   1.���[�X�I����FROM
      ,iv_date_to     --   2.���[�X�I����TO
      ,iv_class_from  --   3.���[�X���FROM
      ,iv_class_to    --   4.���[�X���TO
      ,lv_errbuf      -- �G���[�E���b�Z�[�W           --# �Œ� #
      ,lv_retcode     -- ���^�[���E�R�[�h             --# �Œ� #
      ,lv_errmsg      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
    --�G���[�o��
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --���[�U�[�E�G���[���b�Z�[�W
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --�G���[���b�Z�[�W
      );
    END IF;
    --��s�}��
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --�Ώی����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --���������o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�G���[�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�X�L�b�v�����o��
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --�I�����b�Z�[�W
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_cmn
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode;
    --�I���X�e�[�^�X���G���[�̏ꍇ��ROLLBACK����
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
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
END XXCFF004A28C;
/
