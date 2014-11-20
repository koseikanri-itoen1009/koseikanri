create or replace PACKAGE BODY xxcmn_common4_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2012. All rights reserved.
 *
 * Package Name           : xxcmn_common4_pkg(body)
 * Description            : ���ʊ֐�4
 * MD.070(CMD.050)        : T_MD050_BPO_000_���ʊ֐�4.xls
 * Version                : 1.0
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  get_syori_date         F  DATE  �������t�擾
 *  get_purge_period       F  NUM   �o�b�N�A�b�v����/�p�[�W���Ԏ擾�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/18   1.00  SCSK �{�{����    �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_sts_cd_normal CONSTANT VARCHAR2(1) := 'C';
  gv_sts_cd_warn   CONSTANT VARCHAR2(1) := 'G';
  gv_sts_cd_error  CONSTANT VARCHAR2(1) := 'E';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name    CONSTANT VARCHAR2(100) := 'xxcmn_common4_pkg';       -- �p�b�P�[�W��
--
  gn_ret_nomal     CONSTANT NUMBER := 0; -- ����
  gn_ret_error     CONSTANT NUMBER := 1; -- �G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
--
/*****************************************************************************************
 * Function Name     : get_syori_date
 * Description       : �������t�擾
 * Version           : 1.00
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/18    1.00 SCSK �{�{����    �V�K�쐬
 *
 *****************************************************************************************/
  FUNCTION get_syori_date 
    RETURN DATE                         --�������t����t�^�Ŗ߂��B�G���[�̏ꍇ��NULL��߂��B
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_syori_date' ;  --�v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
--
    -- *** ���[�J���ϐ� ***
    lv_work       VARCHAR2(100);        --�ꎞ�i�[�p
    ld_result     DATE;                 --�������ʂ��i�[
--
  BEGIN

    --lv_��Ɨp := TO_CHAR(SYSDATE,'YYYY/MM/DD');
    --ld_result := TO_DATE(lv_��Ɨp,'YYYY/MM/DD');
    lv_work       := TO_CHAR(SYSDATE,'YYYY/MM/DD');
    ld_result     := TO_DATE(lv_work,'YYYY/MM/DD');

    RETURN ld_result;

  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  �Œ蕔 END   #########################################
--
  END get_syori_date ;

/*****************************************************************************************
 * Function Name     : get_purge_period
 * Description      : �o�b�N�A�b�v����/�p�[�W���Ԏ擾�֐�
 * Version          : 1.00
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/18    1.00 SCSK �{�{����    �V�K�쐬
 *
 *****************************************************************************************/
  FUNCTION get_purge_period (
    iv_purge_type IN VARCHAR2,              --�p�[�W�^�C�v(0:�p�[�W���� 1:�o�b�N�A�b�v����)
    iv_purge_code IN VARCHAR2)              --�p�[�W�R�[�h
    RETURN NUMBER                           --�p�[�W���Ԃ𐔒l�Ŗ߂��B�G���[�̏ꍇ��NULL��߂��B
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_purge_period' ;  --�v���O������
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    /*
    lc_lookup_type CONSTANT VARCHAR2(20) :=  'XXCMN_PURGE_PERIOD';
    lc_enable_y    CONSTANT VARCHAR2(1)  :=  'Y';

     ln_result          NUMBER;
     ln_purge_period  NUMBER;
     ln_backup_period NUMBER;

     lt_attribute1      fnd_lookup_values.attribute1%TYPE;
     lt_attribute2      fnd_lookup_values.attribute2%TYPE;
     ld_������        DATE;
    */
    lc_lookup_type    CONSTANT VARCHAR2(20) :=  'XXCMN_PURGE_PERIOD';   --�ėp�}�X�^���擾����L�[(LOOK_UP_TYPE)
    lc_enable_y       CONSTANT VARCHAR2(1)  :=  'Y';                    --�ėp�}�X�^��enabled�J��������p
--
    -- *** ���[�J���ϐ� ***
    lv_errmsg         VARCHAR2(5000); -- �G���[���b�Z�[�W

    ln_result         NUMBER;                 --�������ʂ��i�[
    ln_purge_period   NUMBER;                 --�p�[�W���Ԃ��i�[
    ln_backup_period  NUMBER;                 --�o�b�N�A�b�v���Ԃ��i�[

    lt_attribute1     fnd_lookup_values.attribute1%TYPE;    --DFF1�̒l
    lt_attribute2     fnd_lookup_values.attribute2%TYPE;    --DFF2�̒l
    ld_syori_date     DATE;                                 --������
--
    -- *** ���[�J���E�J�[�\�� ***
--
    -- *** ���[�J���E���R�[�h ***
--
    -- ===============================
    -- ���[�U�[��`��O
    -- ===============================
--
  BEGIN
    --�p�[�W�^�C�v��NULL�̏ꍇ�̓G���[
    /*
    IF iv_purge_type IS NULL THEN
        RAISE �p�����[�^�s����O
    END IF;
    */
    IF iv_purge_type IS NULL THEN
      RETURN NULL; --�p�����[�^�s����NULL��߂�
    END IF;
--
    --�p�[�W�^�C�v��'0','1'�ȊO�̏ꍇ�̓G���[
    /*
    IF iv_purge_type NOT IN ('0','1') THEN
        RAISE �p�����[�^�s����O
    END IF;
    */
    IF iv_purge_type NOT IN ('0','1') THEN
      RETURN NULL; --�p�����[�^�s����NULL��߂�
    END IF;
--
    --�p�[�W�R�[�h��NULL�̏ꍇ�̓G���[
    /*
    IF iv_purge_code IS NULL THEN
        RAISE �p�����[�^�s����O
    END IF;
    */
    IF iv_purge_code IS NULL THEN
      RETURN NULL; --�p�����[�^�s����NULL��߂�
    END IF;


    --���b�N�A�b�v�̗L�����t�����؂��邽�߂ɁA�������t���擾
    --ld_������ := �������t�擾�֐�
    ld_syori_date := get_syori_date;

    BEGIN
      /*
      SELECT
          flv.attribute1,
          flv.attribute2
      INTO
          lt_attribute1,
          lt_attribute2
      FROM
          fnd_lookup_values flv
      WHERE
              flv.lookup_type  = lc_lookup_type
          AND lookup_code      = iv_purge_code
          AND flv.language     = userenv('LANG')
          AND flv.enabled_flag = lc_enable_y
          AND ld_������        BETWEEN NVL( flv.start_date_active, ld_������ )
                                   AND NVL( flv.end_date_active  , ld_������ );
      */
      --���b�N�A�b�v����p�[�W���Ԃ��擾����
      SELECT
          flv.attribute1  AS attribute1,         --�p�[�W����
          flv.attribute2  AS attribute2          --�o�b�N�A�b�v����
      INTO
          lt_attribute1,
          lt_attribute2
      FROM
          fnd_lookup_values flv   --�ėp�}�X�^
      WHERE
              flv.lookup_type  = lc_lookup_type
          AND flv.lookup_code  = iv_purge_code
          AND flv.language     = userenv('LANG')
          AND flv.enabled_flag = lc_enable_y
          AND ld_syori_date    BETWEEN NVL( flv.start_date_active, ld_syori_date)
                                   AND NVL( flv.end_date_active  , ld_syori_date);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
       --���b�N�A�b�v����l���擾�ł��Ȃ������ꍇ�́ANULL��߂�
        RETURN NULL;
    END;

    --DFF���擾�����l��VARCHAR�^�Ȃ̂ŁA���l�ɕϊ�
    BEGIN
      /*
      ln_�p�[�W���� := TO_NUMBER(lv_attribute1);
      ln_�o�b�N�A�b�v���� := TO_NUMBER(lv_attribute2);
      */
      ln_purge_period   := TO_NUMBER(lt_attribute1);  --�p�[�W����
      ln_backup_period  := TO_NUMBER(lt_attribute2);  --�o�b�N�A�b�v����
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END;

    --�����̃p�[�W�^�C�v�ɂ��A�߂�l��ݒ�
    /*
    iv_�p�[�W�^�C�v��"0"�̏ꍇ
          ln_���� := ln_�p�[�W����
    iv_�p�[�W�^�C�v��"1"�̏ꍇ
          ln_���� := ln_�o�b�N�A�b�v����
    */
    CASE iv_purge_type
      WHEN '0' THEN
        ln_result := ln_purge_period;
      WHEN '1' THEN
        ln_result := ln_backup_period;
    END CASE;
--
    /*
    RETURN ln_����;
    */
    RETURN ln_result;

  EXCEPTION
--
--###############################  �Œ��O������ START   ###################################
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM,1,5000),TRUE);
--###################################  �Œ蕔 END   #########################################
--
  END get_purge_period ;

END xxcmn_common4_pkg;
/
