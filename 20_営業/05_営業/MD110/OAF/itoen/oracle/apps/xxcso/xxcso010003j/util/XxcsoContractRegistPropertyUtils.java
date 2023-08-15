/*============================================================================
* �t�@�C���� : XxcsoSpDecisionPropertyUtils
* �T�v����   : ���̋@�ݒu�_����o�^�\�������v���p�e�B�ݒ胆�[�e�B���e�B�N���X
* �o�[�W���� : 1.5
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-28 1.0  SCS�������l  �V�K�쐬
* 2009-02-16 1.1  SCS�������l  [CT1-008]BM�w��`�F�b�N�{�b�N�X�s���Ή�
* 2010-02-09 1.2  SCS�������  [E_�{�ғ�_01538]�_�񏑂̕����m��Ή�
* 2012-06-12 1.3  SCSK�ː��a�K [E_�{�ғ�_09602]�_�����{�^���ǉ��Ή�
* 2015-02-02 1.4  SCSK�R���đ� [E_�{�ғ�_12565]SP�ꌈ�E�_�񏑉�ʉ��C
* 2023-06-08 1.5  SCSK�Ԓn�w     [E_�{�ғ�_19179]�C���{�C�X�Ή��iBM�֘A�j
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.util;

import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractCreateInitVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractCreateInitVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoLoginUserAuthorityVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoLoginUserAuthorityVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistConstants;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * ���̋@�ݒu�_����o�^�\�������v���p�e�B�ݒ胆�[�e�B���e�B�N���X�B
 * @author  SCS�������l
 * @version 1.1
 *******************************************************************************
 */
public class XxcsoContractRegistPropertyUtils 
{
  /*****************************************************************************
   * �\�������v���p�e�B�ݒ�
   * @param pageRdrVo �y�[�W�����ݒ�r���[�C���X�^���X
   * @param mngVo     �_��Ǘ��e�[�u�����r���[�C���X�^���X
   * @param createVo  �����\�����擾�r���[�C���X�^���X
   *****************************************************************************
   */
  public static void setAttributeProperty(
    XxcsoPageRenderVOImpl                pageRdrVo
   ,XxcsoLoginUserAuthorityVOImpl        userAuthVo
   ,XxcsoContractManagementFullVOImpl    mngVo
   ,XxcsoContractCreateInitVOImpl        createVo
  )
  {
    // �f�[�^�s�擾
    XxcsoPageRenderVORowImpl pageRdrRow
      = (XxcsoPageRenderVORowImpl) pageRdrVo.first();

    XxcsoLoginUserAuthorityVORowImpl userAuthRow
      = (XxcsoLoginUserAuthorityVORowImpl) userAuthVo.first();

    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first(); 

    XxcsoContractCreateInitVORowImpl  createRow
      = (XxcsoContractCreateInitVORowImpl) createVo.first();

    // ////////////////////
    // �����̔��@�ݒu�_�񏑃f�[�^ �o�^����
    // ////////////////////
    if ( mngRow.getContractManagementId().intValue() > 0 )
    {
      // �o�^�f�[�^����PDF�쐬�{�^���\��
      pageRdrRow.setPrintPdfButtonRender(Boolean.TRUE);
    }
    else
    {
      pageRdrRow.setPrintPdfButtonRender(Boolean.FALSE);
    }

    // ////////////////////
    // �X�e�[�^�X����
    // ////////////////////
    // �X�e�[�^�X���m��ς݂̏ꍇ
    if ( isStatusDecision( mngRow.getStatus() ) )
    {
      setPageSecurityNone(pageRdrRow);
    }
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add Start
    else if ( isStatusReject( mngRow.getStatus() ) )
    {
    // �X�e�[�^�X������ς݂̏ꍇ
      setPageSecurityNone(pageRdrRow);
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add End
    }
    // ��L�ȊO�̃X�e�[�^�X�̏ꍇ
    else
    {
// 2010-02-09 [E_�{�ғ�_01538] Mod Start
      String ContractNumber1 = mngRow.getContractNumber();
      String ContractNumber2 = mngRow.getLatestContractNumber();
      // �_�񏑐V������
      if (! isContractNumberCheck(mngRow.getContractNumber(),
                                  mngRow.getLatestContractNumber()
                                 )
         )
      {
        setPageSecurityNone(pageRdrRow);
      }
      else
      {
// 2010-02-09 [E_�{�ғ�_01538] Mod End
        // ���O�C�����[�U�[�����ɂ��y�[�W�����ݒ�
        if (userAuthRow != null)
        {
          String userAuth = userAuthRow.getUserAuthority();
          // �����Ȃ�
          if (XxcsoContractRegistConstants.AUTH_NONE.equals(userAuth))
          {
            setPageSecurityNone(pageRdrRow);
          }
          // �l���c�ƈ��܂��͔���S���c�ƈ�
          else if (XxcsoContractRegistConstants.AUTH_ACCOUNT.equals(userAuth))
          {
            setPageSecurityAccount(pageRdrRow);
          }
          // ���_��
          else if (XxcsoContractRegistConstants.AUTH_BASE_LEADER.equals(userAuth))
          {
            setPageSecurityBaseLeader(pageRdrRow);
          }
          // ��L�ȊO�͑z��O�̂��߁A�ҏW�s��Ԃɂ���
          else
          {
            setPageSecurityNone(pageRdrRow);
          }
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add Start
          // �V�K�o�^�̏ꍇ�A�_�����{�^���͉����s�Ƃ���
          if ( mngRow.getContractManagementId().intValue() < 0 )
          {
            pageRdrRow.setRejectButtonRender(Boolean.FALSE);
          }
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add End
        }
        else
        {
          setPageSecurityNone(pageRdrRow);
        }
// 2010-02-09 [E_�{�ғ�_01538] Mod Start
      }
// 2010-02-09 [E_�{�ғ�_01538] Mod End
    }

    // /////////////////////
    // �U�����E���ߓ���񃊁[�W�����ҏW�ېݒ�
    // /////////////////////
    String lineCount = createRow.getLineCount();
    if ( ! "0".equals(lineCount) )
    {
      pageRdrRow.setPayCondInfoEnabled( Boolean.TRUE);
      pageRdrRow.setPayCondInfoDisabled(Boolean.FALSE);
    }
    else
    {
      pageRdrRow.setPayCondInfoEnabled( Boolean.FALSE);
      pageRdrRow.setPayCondInfoDisabled(Boolean.TRUE);
    }

    // ���ݒ��ɍēx�ݒ蔻��i�y�[�W���̂̃Z�L�����e�B�l���j
    if ( pageRdrRow.getPayCondInfoViewRender().booleanValue() )
    {
      pageRdrRow.setPayCondInfoEnabled(Boolean.FALSE);
      if ( pageRdrRow.getPayCondInfoDisabled().booleanValue() ) 
      {
        pageRdrRow.setPayCondInfoViewRender( Boolean.FALSE );
      }
    }

    // /////////////////////
    // BM1�w��`�F�b�N�{�b�N�X
    // /////////////////////
    if ( isBmCheck(createRow.getBm1SpCustId(), createRow.getBm1PaymentType() ) )
    {
      pageRdrRow.setBm1ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_ON
      );
      pageRdrRow.setBm1Enabled( Boolean.TRUE);
      pageRdrRow.setBm1Disabled(Boolean.FALSE);
    }
    else
    {
      pageRdrRow.setBm1ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_OFF
      );
      pageRdrRow.setBm1Enabled( Boolean.FALSE);
      pageRdrRow.setBm1Disabled(Boolean.TRUE);
    }

    // /////////////////////
    // BM2�w��`�F�b�N�{�b�N�X
    // /////////////////////
    if ( isBmCheck(createRow.getBm2SpCustId(), createRow.getBm2PaymentType() ) )
    {
      pageRdrRow.setBm2ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_ON
      );
      pageRdrRow.setBm2Enabled( Boolean.TRUE);
      pageRdrRow.setBm2Disabled(Boolean.FALSE);
    }
    else
    {
      pageRdrRow.setBm2ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_OFF
      );
      pageRdrRow.setBm2Enabled( Boolean.FALSE);
      pageRdrRow.setBm2Disabled(Boolean.TRUE);
    }

    // /////////////////////
    // BM3�w��`�F�b�N�{�b�N�X
    // /////////////////////
    if ( isBmCheck(createRow.getBm3SpCustId(), createRow.getBm3PaymentType() ) )
    {
      pageRdrRow.setBm3ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_ON
      );
      pageRdrRow.setBm3Enabled( Boolean.TRUE);
      pageRdrRow.setBm3Disabled(Boolean.FALSE);
    }
    else
    {
      pageRdrRow.setBm3ExistFlag(
        XxcsoContractRegistConstants.BM_EXIST_FLAG_OFF
      );
      pageRdrRow.setBm3Enabled( Boolean.FALSE);
      pageRdrRow.setBm3Disabled(Boolean.TRUE);
    }

//2015-02-02 [E_�{�ғ�_12565] Add Start
    // /////////////////////
    // �ݒu���^���w��`�F�b�N�{�b�N�X
    // /////////////////////
    if ( isInstSuppCheck(createRow.getInstSuppType() ))
    {
      pageRdrRow.setInstSuppExistFlag(
        XxcsoContractRegistConstants.INST_SUPP_EXIST_FLAG_ON
      );
      pageRdrRow.setInstSuppEnabled( Boolean.TRUE);
      pageRdrRow.setInstSuppDisabled(Boolean.FALSE);
    }
    else
    {
      pageRdrRow.setInstSuppExistFlag(
        XxcsoContractRegistConstants.INST_SUPP_EXIST_FLAG_OFF
      );
      pageRdrRow.setInstSuppEnabled( Boolean.FALSE);
      pageRdrRow.setInstSuppDisabled(Boolean.TRUE);
    }

    // /////////////////////
    // �Љ�萔���w��`�F�b�N�{�b�N�X
    // /////////////////////
    if ( isIntroChgCheck(createRow.getIntroChgType()) )
    {
      pageRdrRow.setIntroChgExistFlag(
        XxcsoContractRegistConstants.INTRO_CHG_EXIST_FLAG_ON
      );
      pageRdrRow.setIntroChgEnabled( Boolean.TRUE);
      pageRdrRow.setIntroChgDisabled(Boolean.FALSE);
    }
    else
    {
      pageRdrRow.setIntroChgExistFlag(
        XxcsoContractRegistConstants.INTRO_CHG_EXIST_FLAG_OFF
      );
      pageRdrRow.setIntroChgEnabled( Boolean.FALSE);
      pageRdrRow.setIntroChgDisabled(Boolean.TRUE);
    }

    // /////////////////////
    // �d�C��w��`�F�b�N�{�b�N�X
    // /////////////////////
    if ( isElectricCheck(createRow.getElectricPaymentType()) )
    {
      pageRdrRow.setElectricExistFlag(
        XxcsoContractRegistConstants.ELECTRIC_EXIST_FLAG_ON
      );
      pageRdrRow.setElectricEnabled( Boolean.TRUE);
      pageRdrRow.setElectricDisabled(Boolean.FALSE);
    }
    else
    {
      pageRdrRow.setElectricExistFlag(
        XxcsoContractRegistConstants.ELECTRIC_EXIST_FLAG_OFF
      );
      pageRdrRow.setElectricEnabled( Boolean.FALSE);
      pageRdrRow.setElectricDisabled(Boolean.TRUE);
    }
//2015-02-02 [E_�{�ғ�_12565] Add End
    // /////////////////////
    // �I�[�i�[�ύX�`�F�b�N�{�b�N�X�ݒ�
    // /////////////////////
    String installCode = mngRow.getInstallCode();
    if ( installCode == null || "".equals(installCode) )
    {
      pageRdrRow.setOwnerChangeFlag(
        XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_OFF
      );
    }
    else
    {
      pageRdrRow.setOwnerChangeFlag(
        XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON
      );
    }
    // �\�������ݒ�p��firePartialAction���Ɠ��l�̃��\�b�h���Ă�
    setAttributeOwnerChange(pageRdrVo);

  }

  /*****************************************************************************
   * �I�[�i�[�ύX�v���p�e�B�ݒ�
   * @param pageRdrVo �y�[�W�����ݒ�r���[�C���X�^���X
   *****************************************************************************
   */
  public static void setAttributeOwnerChange(
    XxcsoPageRenderVOImpl pageRdrVo
  )
  {
    // �\�������pVO
    XxcsoPageRenderVORowImpl pageRdrRow
      = (XxcsoPageRenderVORowImpl) pageRdrVo.first();

    if ( isOwnerChangeFlagChecked( pageRdrRow.getOwnerChangeFlag() ) )
    {
      pageRdrRow.setOwnerChangeRender(Boolean.TRUE);
    }
    else
    {
      pageRdrRow.setOwnerChangeRender(Boolean.FALSE);
    }
  }
// Ver.1.5 Add Start
  /*****************************************************************************
   * BM1�Ōv�Z�敪�v���_�E��ReadOnly�ݒ�
   * @param pageRdrVo �y�[�W�����ݒ�r���[�C���X�^���X
   * @param Boolean ReadOnly
   *****************************************************************************
   */
  public static void setBm1InvoiceReadOnly(
     XxcsoPageRenderVOImpl pageRdrVo
    ,Boolean readOnlyFlg
  )
  {
    // �\�������pVO
    XxcsoPageRenderVORowImpl pageRdrRow
      = (XxcsoPageRenderVORowImpl) pageRdrVo.first();
    pageRdrRow.setBm1InvoiceReadOnlyFlg(readOnlyFlg);
  }
  
  /*****************************************************************************
   * BM2�Ōv�Z�敪�v���_�E��ReadOnly�ݒ�
   * @param pageRdrVo �y�[�W�����ݒ�r���[�C���X�^���X
   * @param Boolean ReadOnly
   *****************************************************************************
   */
  public static void setBm2InvoiceReadOnly(
     XxcsoPageRenderVOImpl pageRdrVo
    ,Boolean readOnlyFlg
  )
  {
    // �\�������pVO
    XxcsoPageRenderVORowImpl pageRdrRow
      = (XxcsoPageRenderVORowImpl) pageRdrVo.first();
    pageRdrRow.setBm2InvoiceReadOnlyFlg(readOnlyFlg);
  }
  
  /*****************************************************************************
   * BM3�Ōv�Z�敪�v���_�E��ReadOnly�ݒ�
   * @param pageRdrVo �y�[�W�����ݒ�r���[�C���X�^���X
   * @param Boolean ReadOnly
   *****************************************************************************
   */
  public static void setBm3InvoiceReadOnly(
     XxcsoPageRenderVOImpl pageRdrVo
    ,Boolean readOnlyFlg
  )
  {
    // �\�������pVO
    XxcsoPageRenderVORowImpl pageRdrRow
      = (XxcsoPageRenderVORowImpl) pageRdrVo.first();
    pageRdrRow.setBm3InvoiceReadOnlyFlg(readOnlyFlg);
  }
// Ver.1.5 Add Start
  /*****************************************************************************
   * �y�[�W�Z�L�����e�B�ݒ�(�c�ƈ��̗��p)
   * @param pageRdrVo �y�[�W�����ݒ�r���[�C���X�^���X
   *****************************************************************************
   */
  private static void setPageSecurityAccount(
    XxcsoPageRenderVORowImpl pageRdrRow
  )
  {
    // �y�[�W         :�ҏW�\
    pageRdrRow.setRegionViewRender(Boolean.FALSE);
    pageRdrRow.setPayCondInfoViewRender(Boolean.FALSE);
    pageRdrRow.setRegionInputRender(Boolean.TRUE);
    // �ۑ��{�^��     :�����\
    pageRdrRow.setApplyButtonRender(Boolean.TRUE);
    // �m��{�^��     :�����s��
    pageRdrRow.setSubmitButtonRender(Boolean.FALSE);
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add Start
    // �_�����{�^�� :�����\
    pageRdrRow.setRejectButtonRender(Boolean.TRUE);
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add End
  }

  /*****************************************************************************
   * �y�[�W�Z�L�����e�B�ݒ�(���_��)
   * @param pageRdrVo �y�[�W�����ݒ�r���[�C���X�^���X
   *****************************************************************************
   */
  private static void setPageSecurityBaseLeader(
    XxcsoPageRenderVORowImpl pageRdrRow
  )
  {
    // �y�[�W         :�ҏW�\
    pageRdrRow.setRegionViewRender(Boolean.FALSE);
    pageRdrRow.setPayCondInfoViewRender(Boolean.FALSE);
    pageRdrRow.setRegionInputRender(Boolean.TRUE);
    // �ۑ��{�^��     :�����\
    pageRdrRow.setApplyButtonRender(Boolean.TRUE);
    // �m��{�^��     :�����\
    pageRdrRow.setSubmitButtonRender(Boolean.TRUE);
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add Start
    // �_�����{�^�� :�����\
    pageRdrRow.setRejectButtonRender(Boolean.TRUE);
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add End
  }
  
  /*****************************************************************************
   * �y�[�W�Z�L�����e�B�ݒ�(�m�莞)
   * @param pageRdrVo �y�[�W�����ݒ�r���[�C���X�^���X
   *****************************************************************************
   */
  private static void setPageSecurityStatusFix(
    XxcsoPageRenderVORowImpl pageRdrRow
  )
  {
    // �y�[�W         :�ҏW�s��
    pageRdrRow.setRegionViewRender(Boolean.TRUE);
    pageRdrRow.setPayCondInfoViewRender(Boolean.TRUE);
    pageRdrRow.setRegionInputRender(Boolean.FALSE);
    // �ۑ��{�^��     :�����s��
    pageRdrRow.setApplyButtonRender(Boolean.FALSE);
    // �m��{�^��     :�����s��
    pageRdrRow.setSubmitButtonRender(Boolean.FALSE);
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add Start
    // �_�����{�^�� :�����s��
    pageRdrRow.setRejectButtonRender(Boolean.FALSE);
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add End
  }
  

  /*****************************************************************************
   * �y�[�W�Z�L�����e�B�ݒ�(�ҏW�s�̎Q�Ə��)
   * @param pageRdrVo �y�[�W�����ݒ�r���[�C���X�^���X
   * @return boolean true:ON false:OFF
   *****************************************************************************
   */
  private static void setPageSecurityNone(
    XxcsoPageRenderVORowImpl pageRdrRow
  )
  {
    // �y�[�W         :�ҏW�s��
    pageRdrRow.setRegionViewRender(Boolean.TRUE);
    pageRdrRow.setPayCondInfoViewRender(Boolean.TRUE);
    pageRdrRow.setRegionInputRender(Boolean.FALSE);

    // �ۑ��{�^��     :�����s��
    pageRdrRow.setApplyButtonRender(Boolean.FALSE);
    // �m��{�^��     :�����s��
    pageRdrRow.setSubmitButtonRender(Boolean.FALSE);
    // PDF�쐬�{�^��  :�����s��
    pageRdrRow.setPrintPdfButtonRender(Boolean.FALSE);
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add Start
    // �_�����{�^�� :�����s��
    pageRdrRow.setRejectButtonRender(Boolean.FALSE);
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add End
  }

  /*****************************************************************************
   * �_��Ǘ��X�e�[�^�X�m��ςݔ���
   * @param  status �_��Ǘ��e�[�u��.�X�e�[�^�X
   * @return boolean true:�m��ς� false:�m��ς݈ȊO
   *****************************************************************************
   */
  private static boolean isStatusDecision(String status)
  {
    return XxcsoContractRegistConstants.STS_FIX.equals(status);
  }
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add Start
  /*****************************************************************************
   * �_��Ǘ��X�e�[�^�X����ςݔ���
   * @param  status �_��Ǘ��e�[�u��.�X�e�[�^�X
   * @return boolean true:����ς� false:����ς݈ȊO
   *****************************************************************************
   */
  private static boolean isStatusReject(String status)
  {
    return XxcsoContractRegistConstants.STS_REJECT.equals(status);
  }
// 2012-06-12 Ver1.3 [E_�{�ғ�_09602] Add End
  /*****************************************************************************
   * �I�[�i�[�ύX�`�F�b�N�{�b�N�X�`�F�b�N����
   * @param  ownerChangeFlag �`�F�b�N�{�b�N�XValue
   * @return boolean true:ON false:OFF
   *****************************************************************************
   */
  private static boolean isOwnerChangeFlagChecked(String ownerChangeFlag)
  {
    return XxcsoContractRegistConstants.OWNER_CHANGE_FLAG_ON.equals(
            ownerChangeFlag
           );
  }

  /*****************************************************************************
   * BM�w��`�F�b�N�{�b�N�X�`�F�b�N����
   * @param  spCustId      SP�ꌈ�ڋqID
   * @param  bmPaymentType BM�x���敪
   * @return boolean       true:�`�F�b�N��ON false:�`�F�b�N��OFF
   *****************************************************************************
   */
  private static boolean isBmCheck(
    Number spCustId
   ,String bmPaymentType)
  {
    boolean retVal = false;

    if ( spCustId != null)
    {
      if (XxcsoContractRegistConstants.BM_PAYMENT_TYPE5.equals(bmPaymentType))
      {
        retVal = false;
      }
      else
      {
        retVal = true;
      }
    }
    return retVal;
  }
  
//2015-02-02 [E_�{�ғ�_12565] Add Start
  /*****************************************************************************
   * �ݒu���^���`�F�b�N�{�b�N�X�`�F�b�N����
   * @param  instSuppType �x���敪�i�ݒu���^���j
   * @return boolean       true:�`�F�b�N��ON false:�`�F�b�N��OFF
   *****************************************************************************
   */
  private static boolean isInstSuppCheck(
    String instSuppType)
  {
    boolean retVal = false;

    if ( instSuppType != null)
    {
      if (XxcsoContractRegistConstants.INST_SUPP_TYPE0.equals(instSuppType))
      {
        retVal = false;
      }
      else
      {
        retVal = true;
      }
    }
    return retVal;
  }

  /*****************************************************************************
   * �Љ�萔���`�F�b�N�{�b�N�X�`�F�b�N����
   * @param  introChgType �x���敪�i�Љ�萔���j
   * @return boolean       true:�`�F�b�N��ON false:�`�F�b�N��OFF
   *****************************************************************************
   */
  private static boolean isIntroChgCheck(
    String introChgType)
  {
    boolean retVal = false;

    if ( introChgType != null)
    {
      if (XxcsoContractRegistConstants.INTRO_CHG_TYPE0.equals(introChgType))
      {
        retVal = false;
      }
      else
      {
        retVal = true;
      }
    }
    return retVal;
  }

  /*****************************************************************************
   * �d�C��`�F�b�N�{�b�N�X�`�F�b�N����
   * @param  electricPaymentType �x�������i�d�C��j
   * @return boolean       true:�`�F�b�N��ON false:�`�F�b�N��OFF
   *****************************************************************************
   */
  private static boolean isElectricCheck(
    String electricPaymentType)
  {
    boolean retVal = false;

    if ( electricPaymentType != null)
    {
      if (XxcsoContractRegistConstants.ELECTRIC_PAYMENT_TYPE1.equals(electricPaymentType))
      {
        retVal = false;
      }
      else
      {
        retVal = true;
      }
    }
    return retVal;
  }
//2015-02-02 [E_�{�ғ�_12565] Add End


// 2010-02-09 [E_�{�ғ�_01538] Mod Start
  /*****************************************************************************
   * �_�񏑐V������
   * @param  ContractNumber1 �_�񏑔ԍ��i���݁j
   * @param  ContractNumber2 �_�񏑔ԍ��i�ŐV�j
   * @return boolean         true:�V�_�� false:���_��
   *****************************************************************************
   */
  private static boolean isContractNumberCheck(
    String ContractNumber1
   ,String ContractNumber2)
  {
    boolean retVal = false;

    if ( ContractNumber1 == null)
    {
      return true;
    }
    if ( ContractNumber2 == null)
    {
      return true;
    }
    // �ŐV�̌_�񏑂̏ꍇ
    if ( ContractNumber1.equals(ContractNumber2))
    {
      retVal = true;
    }
    else
    {
      retVal = false;
    }
    return retVal;
  }
// 2010-02-09 [E_�{�ғ�_01538] Mod End


}