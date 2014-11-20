CREATE OR REPLACE PACKAGE BODY xxcmm_003common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxcmm_003common_pkg(body)
 * Description            :
 * MD.110                 : MD110_CMM_�ڋq_���ʊ֐�
 * Version                : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  cust_status_update_check  F           �ڋq�X�e�[�^�X�X�V�ۃ`�F�b�N
 *  update_hz_party           P           �p�[�e�B�}�X�^�X�V�p�֐�
 *  cust_name_kana_check      F           �ڋq���́E�ڋq���̃J�i�`�F�b�N
 *  cust_site_check           F           �ڋq���ݒn�S�p���p�`�F�b�N
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2009-01-30    1.0  Yuuki.Nakamura   �V�K�쐬
 *  2009-02-26    1.1  Yutaka.Kuboshima �p�[�e�B�}�X�^�X�V�֐��ǉ�
 *  2009-03-26    1.2  Yutaka.Kuboshima �ڋq���́E�ڋq���̃J�i�`�F�b�N
 *                                      �ڋq���ݒn�S�p���p�`�F�b�N�ǉ�
 *****************************************************************************************/
  -- ===============================
  -- �O���[�o���ϐ�
  -- ===============================
  cv_msg_part     CONSTANT VARCHAR2(100) := ' : ';
  cv_msg_cont     CONSTANT VARCHAR2(3)   := '.';
--
  cv_pkg_name     CONSTANT VARCHAR2(100) := 'XXCMM_003COMMON_PKG';              -- �p�b�P�[�W��
  cv_cnst_period  CONSTANT VARCHAR2(1)   := '.';                                -- �s���I�h
--
  cv_success      CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal; -- ����:0
  cv_error        CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;  -- �ُ�:2
  cv_success_api  CONSTANT VARCHAR2(1)   := 'S';                                -- API�������ԋp�X�e�[�^�X
  cv_user_entered CONSTANT VARCHAR2(12)  := 'USER_ENTERED';                     --�p�[�e�B�}�X�^�X�V�`�o�h�R���e���c�\�[�X�^�C�v
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
--
  /**********************************************************************************
   * Function  Name   : cust_status_update_allow
   * Description      : �ڋq�X�e�[�^�X�X�V�ۃ`�F�b�N
   ***********************************************************************************/
  --���^�[���R�[�hnormal�̂Ƃ��X�V�\�B���^�[���R�[�herror�̂Ƃ��X�V�s�B
  FUNCTION cust_status_update_allow(iv_cust_class        IN VARCHAR2  -- �ڋq�敪
                                   ,iv_cust_status       IN VARCHAR2  -- �ڋq�X�e�[�^�X�i�ύX�O�j
                                   ,iv_cust_will_status  IN VARCHAR2) -- �ڋq�X�e�[�^�X�i�ύX��j
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_kyoten         CONSTANT VARCHAR2(1) := '1';
    cv_out_cust       CONSTANT VARCHAR2(2) := '99';
    cv_rectif_credit  CONSTANT VARCHAR2(2) := '80';
    cv_stop_approved  CONSTANT VARCHAR2(2) := '90';
    cv_mc             CONSTANT VARCHAR2(2) := '20';
    cv_sp_approved    CONSTANT VARCHAR2(2) := '25';
    cv_approved       CONSTANT VARCHAR2(2) := '30';
    cv_cust           CONSTANT VARCHAR2(2) := '40';
    cv_rested         CONSTANT VARCHAR2(2) := '50';
    cv_customer       CONSTANT VARCHAR2(2) := '10';
    cv_su_customer    CONSTANT VARCHAR2(2) := '12';
    cv_trust_corp     CONSTANT VARCHAR2(2) := '13';
    cv_ar_manage      CONSTANT VARCHAR2(2) := '14';
    cv_root           CONSTANT VARCHAR2(2) := '15';
    cv_wholesale      CONSTANT VARCHAR2(2) := '16';
    cv_planning       CONSTANT VARCHAR2(2) := '17';
    cv_edi            CONSTANT VARCHAR2(2) := '18';
    cv_hyakka         CONSTANT VARCHAR2(2) := '19';
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
  --
  BEGIN
    IF (iv_cust_status = iv_cust_will_status) THEN
      RETURN cv_success;
    ELSIF (iv_cust_class = cv_kyoten) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF (iv_cust_class = cv_customer) THEN
      IF (iv_cust_status = cv_mc) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_sp_approved) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_approved) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_cust) AND ((iv_cust_will_status = cv_rested) OR (iv_cust_will_status = cv_rectif_credit) OR (iv_cust_will_status = cv_stop_approved)) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rested) AND ((iv_cust_will_status = cv_mc) OR (iv_cust_will_status = cv_cust) OR (iv_cust_will_status = cv_rectif_credit) OR (iv_cust_will_status = cv_stop_approved)) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rectif_credit) AND (iv_cust_will_status = cv_stop_approved)  THEN
        RETURN cv_success;
      END IF;
    ELSIF (iv_cust_class = cv_su_customer) THEN
      IF (iv_cust_status = cv_approved) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF (iv_cust_class = cv_trust_corp) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_rectif_credit) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rectif_credit) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF (iv_cust_class = cv_ar_manage) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_rectif_credit) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_rectif_credit) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      ELSIF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    ELSIF ((iv_cust_class = cv_root) OR (iv_cust_class = cv_wholesale) OR (iv_cust_class = cv_planning) OR (iv_cust_class = cv_edi) OR (iv_cust_class = cv_hyakka)) THEN
      IF (iv_cust_status = cv_out_cust) AND (iv_cust_will_status = cv_stop_approved) THEN
        RETURN cv_success;
      END IF;
    END IF;
    RETURN cv_error;
  END cust_status_update_allow;
  /**********************************************************************************
   * Procedure  Name  : update_hz_party
   * Description      : �p�[�e�B�}�X�^�X�V�֐�
   ***********************************************************************************/
  PROCEDURE update_hz_party(in_party_id    IN  NUMBER,    -- �p�[�e�BID
                            iv_cust_status IN  VARCHAR2,  -- �ڋq�X�e�[�^�X
                            ov_errbuf      OUT VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
                            ov_retcode     OUT VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
                            ov_errmsg      OUT VARCHAR2)  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  IS
    -- ���[�J���萔
    cv_prg_name                       CONSTANT VARCHAR2(100) := 'update_hz_party'; -- �v���O������
    cv_init_list_api                  CONSTANT VARCHAR2(1)   := 'T';               -- API�N���������X�g�ݒ�l
    -- ���[�J���ϐ�
    lv_return_status                  VARCHAR2(5000);
    ln_msg_count                      NUMBER;
    lv_msg_data                       VARCHAR2(5000);
    lv_retcode                        VARCHAR2(1);
    lv_errmsg                         VARCHAR2(5000);
    ln_party_id                       NUMBER;
    lv_content_source_type            VARCHAR2(12);
    p_party_rec                       hz_party_v2pub.party_rec_type;
    p_organization_rec                hz_party_v2pub.organization_rec_type;
    ln_party_object_version_number    NUMBER;
    ln_profile_id                     NUMBER;
    -- �J�[�\���錾
    -- �p�[�e�B�}�X�^�I�u�W�F�N�g�i���o�[�擾�J�[�\��
    CURSOR get_party_object_number_cur
    IS
      SELECT hp.object_version_number object_version_number
      FROM hz_parties hp
      WHERE hp.party_id = in_party_id;
    -- �p�[�e�B�}�X�^�I�u�W�F�N�g�i���o�[�擾���R�[�h�^
    get_party_object_number_rec get_party_object_number_cur%ROWTYPE;
  BEGIN
    --�p�[�e�BID�ݒ�
    ln_party_id := in_party_id;
    -- �I�u�W�F�N�g�i���o�[�擾
    OPEN get_party_object_number_cur;
    FETCH get_party_object_number_cur INTO get_party_object_number_rec;
    CLOSE get_party_object_number_cur;
    -- �R���e���g�\�[�X�^�C�v�ݒ�
    lv_content_source_type := cv_user_entered;
    --�g�D���擾API
    hz_party_v2pub.get_organization_rec(cv_init_list_api,
                                        ln_party_id,
                                        lv_content_source_type,
                                        p_organization_rec,
                                        lv_return_status,
                                        ln_msg_count,
                                        lv_msg_data);
    -- �G���[������
    IF (lv_return_status <> cv_success_api) THEN
      RAISE global_api_expt;
    END IF;
    --�p�[�e�B���擾API
    hz_party_v2pub.get_party_rec(cv_init_list_api,
                                 ln_party_id,
                                 p_party_rec,
                                 lv_return_status,
                                 ln_msg_count,
                                 lv_msg_data);
    --�p�[�e�B���X�V�l�ݒ�
    -- �G���[������
    IF (lv_return_status <> cv_success_api) THEN
      RAISE global_api_expt;
    END IF;
    --�ڋq�X�e�[�^�X�ݒ�
    p_organization_rec.duns_number_c := iv_cust_status;
    -- �I�u�W�F�N�g�i���o�[�ݒ�
    ln_party_object_version_number   := get_party_object_number_rec.object_version_number;
    --�p�[�e�B���ݒ�
    p_organization_rec.party_rec     := p_party_rec;
    --�p�[�e�B�}�X�^�X�VAPI�Ăяo��
    hz_party_v2pub.update_organization(cv_init_list_api,
                                       p_organization_rec,
                                       ln_party_object_version_number,
                                       ln_profile_id,
                                       lv_return_status,
                                       ln_msg_count,
                                       lv_msg_data);
    -- �G���[������
    IF (lv_return_status <> cv_success_api) THEN
      RAISE global_api_expt;
    END IF;
    ov_retcode := cv_success;
  EXCEPTION
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_msg_data;
      ov_errbuf  := SUBSTRB(cv_pkg_name || cv_msg_cont|| cv_prg_name || cv_msg_part || lv_msg_data, 1, 5000);
      ov_retcode := cv_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name || cv_cnst_period || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000), TRUE);
  END update_hz_party;
  /**********************************************************************************
   * Function  Name   : cust_name_kana_check
   * Description      : �ڋq���́E�ڋq���̃J�i�`�F�b�N
   ***********************************************************************************/
  --�ڋq���́E�ڋq���̃J�i�`�F�b�N�B���^�[���R�[�hnormal�̂Ƃ�����B���^�[���R�[�herror�̂Ƃ��G���[�B
  FUNCTION cust_name_kana_check(iv_cust_name_mir           IN VARCHAR2   -- �ڋq����
                               ,iv_cust_name_phonetic_mir  IN VARCHAR2)  -- �ڋq���̃J�i
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
  --
  BEGIN
    IF     NVL(xxccp_common_pkg.chk_double_byte(iv_cust_name_mir),TRUE)
      AND  NVL(xxccp_common_pkg.chk_single_byte(iv_cust_name_phonetic_mir),TRUE) THEN
      RETURN cv_success;
    END IF;
    RETURN cv_error;
  END cust_name_kana_check;
--
  /**********************************************************************************
   * Function  Name   : cust_site_check
   * Description      : �ڋq���ݒn�S�p���p�`�F�b�N
   ***********************************************************************************/
  --�ڋq���ݒn�S�p���p�`�F�b�N�B���^�[���R�[�hnormal�̂Ƃ�����B���^�[���R�[�herror�̂Ƃ��G���[�B
  FUNCTION cust_site_check(iv_cust_site IN VARCHAR2)  -- �ڋq���ݒn������
    RETURN VARCHAR2
  IS
    -- ===============================
    -- ���[�J���萔
    -- ===============================
    cv_dot        CONSTANT VARCHAR2(1) := '.';
    cv_escape_dot CONSTANT VARCHAR2(2) := '\.';
  --
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_cust_site VARCHAR2(3000) := NULL;
  --
  BEGIN
    --�G�X�P�[�v�V�[�P���X��\.�𕶎��񂩂珜��
    lv_cust_site := REPLACE(iv_cust_site, cv_escape_dot);
    IF   (xxccp_common_pkg.chk_number(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                              ,cv_dot
                                                                              ,1))
      AND LENGTHB(xxccp_common_pkg.char_delim_partition( lv_cust_site
                                                        ,cv_dot
                                                        ,1)) = 7)
      AND xxccp_common_pkg.chk_tel_format(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                 ,cv_dot
                                                                                 ,7))
      AND xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                  ,cv_dot
                                                                                  ,2))
      AND xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                  ,cv_dot
                                                                                  ,3))
      AND xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                  ,cv_dot
                                                                                  ,4))
      AND nvl(xxccp_common_pkg.chk_double_byte(xxccp_common_pkg.char_delim_partition(  lv_cust_site
                                                                                      ,cv_dot
                                                                                      ,5)),TRUE) THEN
      RETURN cv_success;
    END IF;
    RETURN cv_error;
  END cust_site_check;
END xxcmm_003common_pkg;