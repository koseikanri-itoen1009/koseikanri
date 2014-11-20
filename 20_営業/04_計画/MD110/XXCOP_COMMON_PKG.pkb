CREATE OR REPLACE PACKAGE BODY XXCOP_COMMON_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOP_COMMON_PKG(body)
 * Description      : ���ʊ֐��p�b�P�[�W(�v��)
 * MD.050           : ���ʊ֐�    MD070_IPO_COP
 * Version          : 1.0
 *
 * Program List
 * ------------------------- ------------------------------------------------------------
 *  Name                      Description
 * ------------------------- -------------------------------------------------------
 *  get_charge_base_code     01.�S�����_�擾�֐�
 *  get_case_quantity        02.�P�[�X�����Z�֐�
 *  delete_upload_table      03.�t�@�C���A�b�v���[�h�e�[�u���f�[�^�폜����
 *  chk_date_format          04.���t�^�`�F�b�N�֐�
 *  chk_number_format        05.���l�^�`�F�b�N�֐�
 *  put_debug_message        06.�f�o�b�O���b�Z�[�W�o�͊֐�
 *  char_delim_partition     07.�f���~�^���������֐�
 *  get_upload_table_info    08.�t�@�C���A�b�v���[�h�e�[�u�����擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/04    1.0                   �V�K�쐬
 *  2009/03/25    1.1   S.Kayahara      �ŏI�s�ɃX���b�V���ǉ�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  --�X�e�[�^�X�E�R�[�h
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --����:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --�x��:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --�ُ�:2
  --WHO�J����
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ##################################

  cv_pkg_name               CONSTANT VARCHAR2(100) := 'xxcop_common_pkg';       -- �p�b�P�[�W��
--
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  resource_busy_expt        EXCEPTION;     -- �f�b�h���b�N�G���[
--
  PRAGMA EXCEPTION_INIT(resource_busy_expt, -54);
--
/************************************************************************
 * Function Name   : get_charge_base_code
 * Description     : ���[�U�ɕR�Â����_�R�[�h���擾����
 ************************************************************************/
  FUNCTION get_charge_base_code
  ( in_user_id      IN NUMBER             -- ���[�U�[ID
  , id_target_date  IN DATE               -- �Ώۓ�
  )
  RETURN VARCHAR2                         -- ���_�R�[�h
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_charge_base_code'; -- �v���O������

    -- *** ���[�J���ϐ� ***
    lv_start_date      per_all_assignments_f.ass_attribute2%type;    -- ���ߓ�
    lv_basecode_new    per_all_assignments_f.ass_attribute5%type;    -- ���_�R�[�h(�V)
    lv_basecode_old    per_all_assignments_f.ass_attribute6%type;    -- ���_�R�[�h(��)
  BEGIN
    ---------------------------------------------------------
    -- ���[�U�}�X�^�E�]�ƈ������}�X�^��苒�_�����擾
    ---------------------------------------------------------
    --�ύX�㏈��
    SELECT paaf.ass_attribute2           -- ���ߓ�
           -- �������_����Ζ��n���_�Ɏ擾���ύX
          ,paaf.ass_attribute5           -- ���_(�V)
          ,paaf.ass_attribute6           -- ���_(��)
    INTO   lv_start_date
        ,  lv_basecode_new
        ,  lv_basecode_old
    FROM   fnd_user                fu    -- ���[�U
          ,per_all_people_f        papf  -- �]�ƈ�
          ,per_all_assignments_f   paaf  -- �]�ƈ�����
          ,per_person_types        ppt   -- �]�ƈ��^�C�v
    WHERE
    -- ���͏��R�t��
           fu.user_id = in_user_id
    -- �]�ƈ��R�t��
    AND    fu.employee_id = papf.person_id
    AND    id_target_date BETWEEN papf.effective_start_date
                              AND NVL(papf.effective_end_date,id_target_date)
    -- �]�ƈ������R�t��
    AND    papf.person_id    = paaf.person_id
    AND    paaf.primary_flag = 'Y'
    AND    id_target_date BETWEEN paaf.effective_start_date
                          AND NVL(paaf.effective_end_Date,id_target_date)
    -- �]�ƈ��敪�R�t��
    AND    papf.person_type_id = ppt.person_type_id
-- 2008/12/24 modified by scs_fukada start
--    AND    ppt.business_group_id  = fnd_global.per_business_group_id
    AND    ppt.business_group_id  = papf.business_group_id
-- 2008/12/24 modified by scs_fukada end
    AND    ppt.system_person_type = 'EMP'
    AND    ppt.active_flag        = 'Y'
    ;
/*
    --�ύX�O�o�b�N�A�b�v
    SELECT paa.ass_attribute2          -- ���ߓ�
        ,  paa.ass_attribute5          -- ���_�R�[�h(�V)
        ,  paa.ass_attribute6          -- ���_�R�[�h(��)
    INTO   lv_start_date
        ,  lv_basecode_new
        ,  lv_basecode_old
    FROM   fnd_user               fu
        ,  per_all_assignments_f  paa
    WHERE  fu.user_id       = in_user_id
    AND    paa.person_id    = fu.employee_id
    AND    paa.primary_flag = 'Y'
    AND    id_target_date BETWEEN paa.effective_start_date
                              AND paa.effective_end_date
    ;
*/
    ---------------------------------------------------------
    -- �Ώۓ������ߓ��ȏ�̏ꍇ�A���_�R�[�h(�V)��߂�
    -- �Ώۓ������ߓ����O�̏ꍇ�A���_�R�[�h(��)��߂�
    ---------------------------------------------------------
    IF (id_target_date >= to_date(replace(lv_start_date,'/',null),'yyyymmdd')) THEN
      return lv_basecode_new;       -- ���_�R�[�h(�V)
    ELSE
      return lv_basecode_old;       -- ���_�R�[�h(��)
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

/************************************************************************
 * Function Name   : get_case_quantity
 * Description     : �i�ڃR�[�h�A����(�i�ڂ̊�P�ʂƂ���j���A
 *                   OPM�i�ڃ}�X�^���Q�Ƃ��A�P�[�X��������P�[�X�����Z�o����
 ************************************************************************/
  PROCEDURE get_case_quantity
  ( iv_item_no                IN  VARCHAR2       -- �i�ڃR�[�h
  , in_individual_quantity    IN  NUMBER         -- �o������
  , in_trunc_digits           IN  NUMBER         -- �؎̂Č���
  , on_case_quantity          OUT NUMBER         -- �P�[�X����
  , ov_retcode                OUT VARCHAR2       -- ���^�[���R�[�h
  , ov_errbuf                 OUT VARCHAR2       -- �G���[�E���b�Z�[�W
  , ov_errmsg                 OUT VARCHAR2       -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_case_quantity'; -- �v���O������

    -- *** ���[�J���ϐ� ***
    cv_msg_application        CONSTANT VARCHAR2(100) := 'XXCOP' ;               -- ����I�����b�Z�[�W
    cv_item_chk_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00013';     -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
    cv_item_chk_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'item';                 --   �g�[�N�����P
    cv_item_chk_msg_tkn_val1  CONSTANT VARCHAR2(100) := '�i�ڃR�[�h';           --   �g�[�N���Z�b�g�l�P
    cv_item_chk_msg_tkn_lbl2  CONSTANT VARCHAR2(100) := 'value';                --   �g�[�N�����Q
    lv_num_of_cases           ic_item_mst_b.attribute11%type;  -- �P�[�X����
    ln_case_quantity          number;
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;

    ---------------------------------------------------------
    -- OPM�i�ڃ}�X�^���P�[�X�������擾
    ---------------------------------------------------------
    BEGIN
      SELECT iimb.attribute11
      INTO   lv_num_of_cases
      FROM   ic_item_mst_b iimb
      WHERE  iimb.item_no = iv_item_no
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        on_case_quantity   := null;
        ov_retcode         := cv_status_error;
        ov_errmsg          := xxccp_common_pkg.get_msg(
                                        iv_application  => cv_msg_application
                                       ,iv_name         => cv_item_chk_msg
                                       ,iv_token_name1  => cv_item_chk_msg_tkn_lbl1
                                       ,iv_token_value1 => cv_item_chk_msg_tkn_val1
                                       ,iv_token_name2  => cv_item_chk_msg_tkn_lbl2
                                       ,iv_token_value2 => iv_item_no
                                       );
        RETURN;
    END;

    ---------------------------------------------------------
    -- �P�[�X���ʎZ�o
    ---------------------------------------------------------
    ln_case_quantity  :=  TRUNC(in_individual_quantity / NVL(TO_NUMBER(lv_num_of_cases),1),in_trunc_digits);

    ---------------------------------------------------------
    -- ����I���F�߂�l�ݒ�
    ---------------------------------------------------------
    on_case_quantity   := ln_case_quantity;

  EXCEPTION
    WHEN OTHERS THEN
      on_case_quantity := NULL;
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  END;

/************************************************************************
 * Procedure Name  : delete_upload_table
 * Description     : �t�@�C���A�b�v���[�h�C���^�[�t�F�[�X�e�[�u����
 *                   �f�[�^���폜����
 ************************************************************************/
  PROCEDURE delete_upload_table
  ( in_file_id    IN  NUMBER          -- �t�@�C���h�c
  , ov_retcode    OUT VARCHAR2        -- ���^�[���R�[�h
  , ov_errbuf     OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_errmsg     OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'delete_upload_table';      -- �v���O������

    -- *** ���[�J���ϐ� ***
    cv_msg_application        CONSTANT VARCHAR2(100) := 'XXCOP' ;                   -- ����I�����b�Z�[�W
    cv_lock_err_msg           CONSTANT VARCHAR2(100) := 'APP-XXCOP1-00007';         -- �}�X�^�`�F�b�N�G���[���b�Z�[�W
    cv_lock_err_msg_tkn_lbl1  CONSTANT VARCHAR2(100) := 'table';                    --   �g�[�N�����P
    cv_lock_err_msg_tkn_val1  CONSTANT VARCHAR2(100) := '�t�@�C���A�b�v���[�hI/F';  --   �g�[�N���Z�b�g�l�P
    ln_file_id                xxccp_mrp_file_ul_interface.file_id%type;
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;

    ----------------------------------------
    -- �A�b�v���[�h�h�e�e�[�u�����b�N
    ----------------------------------------
    BEGIN
      SELECT file_id
      INTO   ln_file_id
      FROM   xxccp_mrp_file_ul_interface
      WHERE  file_id = in_file_id
      FOR UPDATE OF file_id NOWAIT
      ;
    EXCEPTION
      WHEN resource_busy_expt     -- ���\�[�X�r�W�[�i���b�N���j
      OR   NO_DATA_FOUND          -- �Ώۃf�[�^����
      THEN
        ov_retcode   := cv_status_error;
        ov_errmsg    := xxccp_common_pkg.get_msg(
                              iv_application  => cv_msg_application
                             ,iv_name         => cv_lock_err_msg
                             ,iv_token_name1  => cv_lock_err_msg_tkn_lbl1
                             ,iv_token_value1 => cv_lock_err_msg_tkn_val1
                             );
        RETURN;
    END;

    ----------------------------------------
    -- �A�b�v���[�h�h�e�e�[�u���폜
    ----------------------------------------
    DELETE
    FROM   xxccp_mrp_file_ul_interface
    WHERE  file_id = in_file_id
    ;
  EXCEPTION
    WHEN OTHERS THEN
      ov_retcode   := cv_status_error;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  END;

/************************************************************************
 * Procedure Name  : chk_date_format
 * Description     : ���t�^�`�F�b�N�֐�
 ************************************************************************/
  FUNCTION chk_date_format
  ( iv_value      IN  VARCHAR2        -- ������
  , iv_format     IN  VARCHAR2        -- ����
  )
  RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_date_format';      -- �v���O������

    -- *** ���[�J���ϐ� ***
    lv_chk_value   VARCHAR2(200);
    ld_chk_value   DATE;
  BEGIN
    -- ������null�̏ꍇ�AFALSE��߂�
    IF (iv_format IS NULL) THEN
      RETURN FALSE;
    END IF;

    -- ���������������`�F�b�N
    lv_chk_value := TO_CHAR(SYSDATE ,iv_format);

    -- �����񂪏����ʂ��DATE�^�ɕϊ��ł��邩�`�F�b�N
    ld_chk_value := TO_DATE(iv_value, iv_format);

    lv_chk_value := TO_CHAR(ld_chk_value ,iv_format);

    IF (lv_chk_value <> iv_value) THEN
           RETURN FALSE;
    END IF;

    RETURN TRUE;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END;
--
/************************************************************************
 * Procedure Name  : chk_number_format
 * Description     : ���l�^�`�F�b�N�֐�
 ************************************************************************/
  FUNCTION chk_number_format
  ( iv_value      IN  VARCHAR2        -- ������
  )
  RETURN BOOLEAN
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_number_format';      -- �v���O������

    -- *** ���[�J���ϐ� ***
    ln_chk_value   NUMBER;
  BEGIN

    ln_chk_value := TO_NUMBER(iv_value);

    RETURN TRUE;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END;
/************************************************************************
 * Procedure Name  : put_debug_message
 * Description     : �f�o�b�O���b�Z�[�W�o�͊֐�
 ************************************************************************/
  PROCEDURE put_debug_message(
    iv_value       IN      VARCHAR2     -- ������
  , iov_debug_mode IN OUT  VARCHAR2     -- �f�o�b�O���[�h
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'put_debug_message';      -- �v���O������

    -- *** ���[�J���ϐ� ***

  BEGIN

    -- �f�o�b�O���[�h�v���t�@�C���l�擾
    IF (iov_debug_mode IS NULL) THEN
      iov_debug_mode := FND_PROFILE.VALUE('XXCOP1_DEBUG_MODE');
    END IF;

    -- �f�o�b�O���[�h�ɐݒ肳��Ă����烍�O�o��
    IF (iov_debug_mode = 'ON') THEN
      FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => iv_value
      );
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
/************************************************************************
 * Procedure Name  : char_delim_partition
 * Description     : �f���~�^���������֐�
 ************************************************************************/
  PROCEDURE char_delim_partition(
    iv_char       IN  VARCHAR2        -- �Ώە�����
  , iv_delim      IN  VARCHAR2        -- �f���~�^
  , o_char_tab    OUT g_char_ttype    -- ��������
  , ov_retcode    OUT VARCHAR2        -- ���^�[���R�[�h
  , ov_errbuf     OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_errmsg     OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'char_delim_partition';      -- �v���O������

    -- *** ���[�J���ϐ� ***
    ln_index       NUMBER := 0;          -- CSV�C���f�b�N�X
    ln_start       NUMBER := 1;          -- �ǂݎ��J�n�ʒu
    ln_sep         NUMBER;               -- ��؂蕶���̈ʒu
  BEGIN
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
--
    --==============================================================
    --�f�[�^�̃J���}��؂�
    --==============================================================
    <<divide_loop>>
    LOOP
      -- CSV�C���f�b�N�X���J�E���g�A�b�v
      ln_index := ln_index + 1;
--
      -- ��؂蕶���̈ʒu���擾
      ln_sep := NVL( INSTR( iv_char, iv_delim, ln_start ), 0 );
--
      -- �ǂݎ��I���ʒu�̌���
      IF ( ln_sep = 0 ) THEN
        -- ��؂蕶����������Ȃ��ꍇ�͕�����̍Ō�܂ł��uPL/SQL�\�FCSV�v�f�v�Ɋi�[���ďI������
        o_char_tab( ln_index ) := SUBSTR( iv_char, ln_start );
        EXIT divide_loop;
      ELSE
        -- ��؂蕶�������������ꍇ�͂��̎�O�܂ł��uPL/SQL�\�FCSV�v�f�v�Ɋi�[����
        o_char_tab( ln_index ) := SUBSTR( iv_char, ln_start, ( ln_sep - ln_start ) );
        -- ��؂蕶���̒��������̓ǂݎ��J�n�ʒu�Ƃ���
        ln_start := ln_sep + 1;
      END IF;
    END LOOP divide_loop;
--
  EXCEPTION
      WHEN OTHERS THEN
        ov_retcode   := cv_status_error;
        ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  END;
/************************************************************************
 * Procedure Name  : get_upload_table_info
 * Description     : �t�@�C���A�b�v���[�h�e�[�u�����擾
 ************************************************************************/
  PROCEDURE get_upload_table_info(
    in_file_id     IN  NUMBER          -- �t�@�C��ID
  , iv_format      IN  VARCHAR2        -- �t�H�[�}�b�g�p�^�[��
  , ov_upload_name OUT VARCHAR2        -- �t�@�C���A�b�v���[�h����
  , ov_file_name   OUT VARCHAR2        -- �t�@�C����
  , od_upload_date OUT DATE            -- �A�b�v���[�h����
  , ov_retcode     OUT VARCHAR2        -- ���^�[���R�[�h
  , ov_errbuf      OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_errmsg      OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'get_upload_table_info';      -- �v���O������
    cv_lookup_type     CONSTANT VARCHAR2(22)  := 'XXCCP1_FILE_UPLOAD_OBJ';     -- �^�C�v
    cv_enable          CONSTANT VARCHAR2(1)   := 'Y';                          -- �L���t���O
    cd_sysdate         CONSTANT DATE          := TRUNC(SYSDATE);               -- �V�X�e�����t�i�N�����j

    -- *** ���[�J���ϐ� ***
    lv_language        fnd_lookup_values.language%TYPE := USERENV('LANG');  -- LANGUAGE
    lv_upload_name     fnd_lookup_values.meaning%TYPE;
    lv_file_name       xxccp_mrp_file_ul_interface.file_name%TYPE;
    lv_upload_date     xxccp_mrp_file_ul_interface.creation_date%TYPE;
  BEGIN
--
    --==============================================================
    --�X�e�[�^�X������
    --==============================================================
    ov_retcode := cv_status_normal;
    --
    --==============================================================
    --�t�@�C���A�b�v���[�h�C���^�t�F�[�X�e�[�u���̎擾
    --==============================================================
    SELECT xmfui.file_name
          ,xmfui.creation_date
    INTO   lv_file_name
          ,lv_upload_date
    FROM   xxccp_mrp_file_ul_interface xmfui
    WHERE  xmfui.file_id = in_file_id;
    --
    --==============================================================
    --�N�C�b�N�R�[�h�̎擾
    --==============================================================
    SELECT flv.meaning
    INTO   lv_upload_name
    FROM   fnd_lookup_values flv
    WHERE  flv.lookup_type        = cv_lookup_type
    AND    flv.lookup_code        = iv_format
    AND    flv.language           = lv_language
    AND    flv.enabled_flag       = cv_enable
    AND    cd_sysdate BETWEEN NVL(flv.start_date_active,cd_sysdate)
                          AND NVL(flv.end_date_active,cd_sysdate);
    --
    --==============================================================
    --����I��
    --==============================================================
    ov_upload_name     := lv_upload_name;
    ov_file_name       := lv_file_name;
    od_upload_date     := lv_upload_date;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := NULL;
    WHEN OTHERS THEN
      ov_retcode       := cv_status_error;
      ov_errbuf        := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
  END;
--
--###########################   END   ##############################
--
END XXCOP_COMMON_PKG;
/
