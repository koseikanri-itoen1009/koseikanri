/*==============================================================================
* �t�@�C���� : XxcsoContractRegistCO
* �T�v����   : ���̋@�ݒu�_����o�^�R���g���[���N���X
* �o�[�W���� : 1.8
*==============================================================================
* �C������
* ���t       Ver. �S����         �C�����e
* ---------- ---- -------------- ----------------------------------------------
* 2009-01-27 1.0  SCS����_      �V�K�쐬
* 2009-04-09 1.1  SCS�������l    [ST��QT1_0327]���C�A�E�g���������C��
* 2010-02-09 1.2  SCS�������    [E_�{�ғ�_01538]�_�񏑂̕����m��Ή�
* 2011-06-06 1.3  SCS�ː��a�K    [E_�{�ғ�_01963]�V�K�d����쐬�`�F�b�N�Ή�
* 2012-06-12 1.4  SCSK�ː��a�K   [E_�{�ғ�_09602]�_�����{�^���ǉ��Ή�
* 2013-04-01 1.5  SCSK�ː��a�K   [E_�{�ғ�_10413]��s�����}�X�^�ύX�`�F�b�N�ǉ��Ή�
* 2015-02-02 1.6  SCSK�R���đ�   [E_�{�ғ�_12565]SP�ꌈ�E�_�񏑉�ʉ��C
* 2019-02-19 1.7  SCSK���X�ؑ�a [E_�{�ғ�_15349]�d����CD����Ή�
* 2022-03-31 1.8  SCSK�񑺗I��   [E_�{�ғ�_18060]���̋@�ڋq�ʗ��v�Ǘ�
*==============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.util.XxcsoContractRegistConstants;

import java.io.Serializable;

import java.util.Hashtable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLayoutBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageTextInputBean;

/*******************************************************************************
 * �_�񏑌�������󂯂�p�����[�^�m�F�������ʂ̃R���g���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractRegistCO extends OAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /*****************************************************************************
   * ��ʋN�����̏������s���܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    XxcsoUtils.debug(pageContext, "[START]");

    // �o�^�n�����܂�
    if (pageContext.isBackNavigationFired(false))
    {
      XxcsoUtils.unexpected(pageContext, "back navigate");
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    // �_�C�A���O�y�[�W����̑J�ڎ��͑��I��
    if ( pageContext.getParameter(XxcsoConstants.TOKEN_ACTION) != null)
    {
// 2009-04-09 [ST��QT1_0327] Add Start
// 2015-02-02 [E_�{�ғ�_12565] Del Start
//      adjustLayout(pageContext, webBean);
//
//      OAMessageTextInputBean bean
//        = (OAMessageTextInputBean)webBean.findChildRecursive("OtherContent");
//      bean.setReadOnlyTextArea(true);
//      bean.setReadOnly(true);
// 2015-02-02 [E_�{�ғ�_12565] Del End
// 2009-04-09 [ST��QT1_0327] Add End
      return;
    }

    // URL����p�����[�^���擾���܂��B
    String modeType =
        pageContext.getParameter(XxcsoConstants.EXECUTE_MODE);
    String spDecisionHeaderId = 
        pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY1);
    String contractManagementId = 
        pageContext.getParameter(XxcsoConstants.TRANSACTION_KEY2);

    // AM�֓n���������쐬���܂��B
    Serializable[] params =
    {
       spDecisionHeaderId
      ,contractManagementId
    };

    // AM�C���X�^���X���擾���܂��B
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);
    }

    if ( modeType == null || "".equals(modeType) )
    {
      am.invokeMethod("initDetailsCreate", params);
    }
    else if ( XxcsoContractRegistConstants.MODE_UPDATE.equals(modeType) )
    {
      am.invokeMethod("initDetailsUpdate", params);
    }
    else if ( XxcsoContractRegistConstants.MODE_COPY.equals(modeType) )
    {
      am.invokeMethod("initDetailsCopy", params);
    }
    am.invokeMethod("initPopList");
    am.invokeMethod("afterProcess");
    
    am.invokeMethod("setAttributeProperty");

    // ���C�A�E�g����
    adjustLayout(pageContext, webBean);
// 2015-02-02 [E_�{�ғ�_12565] Del Start
//    OAMessageTextInputBean bean
//      = (OAMessageTextInputBean)webBean.findChildRecursive("OtherContent");
//    bean.setReadOnlyTextArea(true);
//    bean.setReadOnly(true);
// 2015-02-02 [E_�{�ғ�_12565] Del End
    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * ��ʃC�x���g�̏������s���܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    XxcsoUtils.debug(pageContext, "[START]");

    // AM�C���X�^���X���擾���܂��B
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    if ( am == null )
    {
      OADialogPage dialogPage = new OADialogPage(STATE_LOSS_ERROR);
      pageContext.redirectToDialogPage(dialogPage);      
    }

    String event = pageContext.getParameter(OAWebBeanConstants.EVENT_PARAM);
    XxcsoUtils.debug(pageContext, "EVENT = " + event);

    /////////////////////////////////////
    // ����{�^��
    /////////////////////////////////////
    if ( pageContext.getParameter("CancelButton") != null )
    {
      am.invokeMethod("handleCancelButton");

      //������ʂɑJ��
      pageContext.forwardImmediately(
        XxcsoConstants.FUNC_CONTRACT_SEARCH_PG
       ,OAWebBeanConstants.KEEP_MENU_CONTEXT
       ,null
       ,null
       ,true
       ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
      );
    }

    /////////////////////////////////////
    // �K�p�{�^��
    /////////////////////////////////////
    if ( pageContext.getParameter("ApplyButton") != null )
    {
      am.invokeMethod("handleApplyButton");

      // ���b�Z�[�W�̎擾
      OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialog(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_SAVE
        );
      }
// 2011-06-06 Ver1.3 [E_�{�ғ�_01963] Add Start

      // ��s�������݃`�F�b�N
      am.invokeMethod("bankAccountCheck");
      // ���b�Z�[�W�̎擾
      confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialog(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_SAVE2
        );
      }

      // �d���摶�݃`�F�b�N
      am.invokeMethod("supplierCheck");
      // ���b�Z�[�W�̎擾
      confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialog(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_SAVE3
        );
      }
// 2011-06-06 Ver1.3 [E_�{�ғ�_01963] Add End

// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
      // ��s�����ύX�`�F�b�N
      am.invokeMethod("bankAccountChangeCheck");
      // ���b�Z�[�W�̎擾
      confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialogWarn(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_WARN1
        );
      }
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
// v1.7 Y.Sasaki Added START
      // ���t����ύX�`�F�b�N
      am.invokeMethod("suppllierChangeCheck");
      confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialogWarn(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_WARN4
        );
      }
// v1.7 Y.Sasaki Added END
// Ver1.8 Add Start
      // �ݒu���^���x�����ڃ`�F�b�N
      am.invokeMethod("installPayItemCheck");
      confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialogWarn(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_WARN7
        );
      }
      // �s�����Y�g�p���x�����ڃ`�F�b�N
      am.invokeMethod("adAssetsPayItemCheck");
      // ���b�Z�[�W�̎擾
      confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialogWarn(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_WARN8
        );
      }
// Ver.1.8 Add End
      else
      {
        // AM�ւ̃p�����[�^�쐬
        Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_SAVE };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
      }
    }

    /////////////////////////////////////
    // �m��{�^��
    /////////////////////////////////////
    if ( pageContext.getParameter("SubmitButton") != null )
    {
      am.invokeMethod("handleSubmitButton");

      // ���b�Z�[�W�̎擾
      OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialog(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_DECISION
        );
      }
      else
      {
// 2011-06-06 Ver1.3 [E_�{�ғ�_01963] Add Start

        // ��s�������݃`�F�b�N
        am.invokeMethod("bankAccountCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION2
          );
        }

        // �d���摶�݃`�F�b�N
        am.invokeMethod("supplierCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION3
          );
        }
// 2011-06-06 Ver1.3 [E_�{�ғ�_01963] Add End

// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
        // ��s�����ύX�`�F�b�N
        am.invokeMethod("bankAccountChangeCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN2
          );
        }
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
// v1.7 Y.Sasaki Added START
        // ���t����ύX�`�F�b�N
        am.invokeMethod("suppllierChangeCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN5
          );
        }
// v1.7 Y.Sasaki Added END
// Ver1.8 Add Start
        // �ݒu���^���x�����ڃ`�F�b�N
        am.invokeMethod("installPayItemCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN9
          );
        }
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN10
          );
        }
// Ver.1.8 Add End
// 2010-02-09 [E_�{�ғ�_01538] Mod Start
        // �}�X�^�A�g�҂��`�F�b�N
        am.invokeMethod("cooperateWaitCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        else
        {
// 2010-02-09 [E_�{�ғ�_01538] Mod End
          // AM�ւ̃p�����[�^�쐬
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_DECISION };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
// 2010-02-09 [E_�{�ғ�_01538] Mod Start
        }
// 2010-02-09 [E_�{�ғ�_01538] Mod End
         
      }
    }

    /////////////////////////////////////
    // PDF�쐬�{�^��
    /////////////////////////////////////
    if ( pageContext.getParameter("PrintPdfButton") != null )
    {

// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
      // ��s�����ύX�`�F�b�N
      am.invokeMethod("bankAccountChangeCheck");
      // ���b�Z�[�W�̎擾
      OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialogWarn(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_WARN3
        );
      }
// v1.7 Y.Sasaki Deleted START
//      else
//      {
// v1.7 Y.Sasaki Deleted END
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
// v1.7 Y.Sasaki Added START
      // ���t����ύX�`�F�b�N
      am.invokeMethod("suppllierChangeCheck");
      confirmMsg = (OAException)am.invokeMethod("getMessage");
      if (confirmMsg != null)
      {
        this.createConfirmDialogWarn(
          pageContext
         ,confirmMsg
         ,XxcsoConstants.TOKEN_VALUE_WARN6
        );
      }
      else
      {
// v1.7 Y.Sasaki Added END
        HashMap returnMap = (HashMap) am.invokeMethod("handlePrintPdfButton");

        this.redirect(pageContext, returnMap);

// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
      }
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End

    }
// 2012-06-12 Ver1.4 [E_�{�ғ�_09602] Add Start
    /////////////////////////////////////
    // �_�����{�^��
    /////////////////////////////////////
    if ( pageContext.getParameter("RejectButton") != null )
    {
      // �_�����m�F
      am.invokeMethod("RejectContract");
      // �m�F���b�Z�[�W�̎擾
      OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
      //�m�F���b�Z�[�W��\��
      this.createConfirmDialog(
        pageContext
       ,confirmMsg
       ,XxcsoConstants.TOKEN_VALUE_REJECT
      );
    }
// 2012-06-12 Ver1.4 [E_�{�ғ�_09602] Add End

    /////////////////////////////////////
    // �m�F�_�C�A���O�ł�OK�{�^��
    /////////////////////////////////////
    if ( pageContext.getParameter("ConfirmOkButton") != null )
    {
      String actionValue
        = pageContext.getParameter(XxcsoConstants.TOKEN_ACTION);

// 2010-02-09 [E_�{�ғ�_01538] Mod Start
      // �m��{�^�����������̏ꍇ
      if ( XxcsoConstants.TOKEN_VALUE_DECISION.equals(actionValue) )
      {
// 2011-06-06 Ver1.3 [E_�{�ғ�_01963] Add Start

        // ��s�������݃`�F�b�N
        am.invokeMethod("bankAccountCheck");
        // ���b�Z�[�W�̎擾
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION2
          );
        }

        // �d���摶�݃`�F�b�N
        am.invokeMethod("supplierCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION3
          );
        }
// 2011-06-06 Ver1.3 [E_�{�ғ�_01963] Add End

// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
        // ��s�����ύX�`�F�b�N
        am.invokeMethod("bankAccountChangeCheck");
        // ���b�Z�[�W�̎擾
         confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN2
          );
        }
// v1.7 Y.Sasaki Added START
        // ���t����ύX�`�F�b�N
        am.invokeMethod("suppllierChangeCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN5
          );
        }
// v1.7 Y.Sasaki Added END
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
// Ver1.8 Add Start
        // �ݒu���^���x�����ڃ`�F�b�N
        am.invokeMethod("installPayItemCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN9
          );
        }
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN10
          );
        }
// Ver.1.8 Add End
        // �}�X�^�A�g�҂��`�F�b�N
        am.invokeMethod("cooperateWaitCheck");
        // ���b�Z�[�W�̎擾
// 2011-06-06 Ver1.3 [E_�{�ғ�_01963] Mod Start
//        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
// 2011-06-06 Ver1.3 [E_�{�ғ�_01963] Mod End
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        else
        {
          // AM�ւ̃p�����[�^�쐬
          Serializable[] params    = { actionValue };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
        }
      }
// 2011-06-06 Ver1.3 [E_�{�ғ�_01963] Add Start
      // �m��{�^��(��s�������݃`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_DECISION2.equals(actionValue) )
      {

        // �d���摶�݃`�F�b�N
        am.invokeMethod("supplierCheck");
        // ���b�Z�[�W�̎擾
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION3
          );
        }

// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
        // ��s�����ύX�`�F�b�N
        am.invokeMethod("bankAccountChangeCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN2
          );
        }
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
// v1.7 Y.Sasaki Added START
        // ���t����ύX�`�F�b�N
        am.invokeMethod("suppllierChangeCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN5
          );
        }
// v1.7 Y.Sasaki Added END
// Ver1.8 Add Start
        // �ݒu���^���x�����ڃ`�F�b�N
        am.invokeMethod("installPayItemCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN9
          );
        }
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN10
          );
        }
// Ver.1.8 Add End
        // �}�X�^�A�g�҂��`�F�b�N
        am.invokeMethod("cooperateWaitCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        else
        {
          // AM�ւ̃p�����[�^�쐬
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_DECISION };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
        }      
      }
      // �m��{�^��(�d���摶�݃`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_DECISION3.equals(actionValue) )
      {

// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
        // ��s�����ύX�`�F�b�N
        am.invokeMethod("bankAccountChangeCheck");
        // ���b�Z�[�W�̎擾
         OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN2
          );
        }
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
// v1.7 Y.Sasaki Added START
        // ���t����ύX�`�F�b�N
        am.invokeMethod("suppllierChangeCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN5
          );
        }
// v1.7 Y.Sasaki Added END
// Ver1.8 Add Start
        // �ݒu���^���x�����ڃ`�F�b�N
        am.invokeMethod("installPayItemCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN9
          );
        }
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN10
          );
        }
// Ver.1.8 Add End
        // �}�X�^�A�g�҂��`�F�b�N
        am.invokeMethod("cooperateWaitCheck");
        // ���b�Z�[�W�̎擾
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Mod Start
//        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Mod End
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        else
        {
          // AM�ւ̃p�����[�^�쐬
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_DECISION };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
        }      
      }
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
      // �m��{�^��(��s�����ύX�`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_WARN2.equals(actionValue) )
      {

// v1.7 Y.Sasaki Added START
        // ���t����ύX�`�F�b�N
        am.invokeMethod("suppllierChangeCheck");
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN5
          );
        }
// v1.7 Y.Sasaki Added END
// Ver1.8 Add Start
        // �ݒu���^���x�����ڃ`�F�b�N
        am.invokeMethod("installPayItemCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN9
          );
        }
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN10
          );
        }
// Ver.1.8 Add End
        // �}�X�^�A�g�҂��`�F�b�N
        am.invokeMethod("cooperateWaitCheck");
// v1.7 Y.Sasaki Modified START
//        // ���b�Z�[�W�̎擾
//        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
// v1.7 Y.Sasaki Modified END
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        else
        {
          // AM�ւ̃p�����[�^�쐬
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_DECISION };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
        }

      }
// v1.7 Y.Sasaki Added START
      // �m��{�^��(���t����ύX�`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_WARN5.equals(actionValue) )
      {
// Ver1.8 Add Start
        // �ݒu���^���x�����ڃ`�F�b�N
        am.invokeMethod("installPayItemCheck");
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN9
          );
        }
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN10
          );
        }
// Ver.1.8 Add End
        // �}�X�^�A�g�҂��`�F�b�N
        am.invokeMethod("cooperateWaitCheck");
        // ���b�Z�[�W�̎擾
// Ver1.8 Mod Start
//        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
// Ver1.8 Mod End
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        // AM�ւ̃p�����[�^�쐬
        Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_DECISION };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
      }
// v1.7 Y.Sasaki Added END
// Ver1.8 Add Start
      // �m��{�^��(�ݒu���^���x�����ڃ`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_WARN9.equals(actionValue) )
      {
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN10
          );
        }
        // �}�X�^�A�g�҂��`�F�b�N
        am.invokeMethod("cooperateWaitCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        // AM�ւ̃p�����[�^�쐬
        Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_DECISION };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
      }
      // �m��{�^��(�s�����Y�g�p���x�����ڃ`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_WARN10.equals(actionValue) )
      {
        // �}�X�^�A�g�҂��`�F�b�N
        am.invokeMethod("cooperateWaitCheck");
        // ���b�Z�[�W�̎擾
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogCooperate(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_DECISION
          );
        }
        // AM�ւ̃p�����[�^�쐬
        Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_DECISION };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
      }
// Ver.1.8 Add End
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
      // �K�p�{�^��(�����ڋq�w�著�t��)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_SAVE.equals(actionValue) )
      {
        // ��s�������݃`�F�b�N
        am.invokeMethod("bankAccountCheck");
        // ���b�Z�[�W�̎擾
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_SAVE2
          );
        }

        // �d���摶�݃`�F�b�N
        am.invokeMethod("supplierCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_SAVE3
          );
        }

// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
        // ��s�����ύX�`�F�b�N
        am.invokeMethod("bankAccountChangeCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN1
          );
        }
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
// v1.7 Y.Sasaki Added START
        // ���t����ύX�`�F�b�N
        am.invokeMethod("suppllierChangeCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN4
          );
        }
// v1.7 Y.Sasaki Added END
// Ver1.8 Add Start
        // �ݒu���^���x�����ڃ`�F�b�N
        am.invokeMethod("installPayItemCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN7
          );
        }
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN8
          );
        }
// Ver.1.8 Add End
        else
        {
          // AM�ւ̃p�����[�^�쐬
          Serializable[] params    = { actionValue };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);          
        }
      }
      // �K�p�{�^��(��s�������݃`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_SAVE2.equals(actionValue) )
      {
        // �d���摶�݃`�F�b�N
        am.invokeMethod("supplierCheck");
        // ���b�Z�[�W�̎擾
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialog(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_SAVE3
          );
        }

// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
        // ��s�����ύX�`�F�b�N
        am.invokeMethod("bankAccountChangeCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN1
          );
        }
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
// v1.7 Y.Sasaki Added START
        // ���t����ύX�`�F�b�N
        am.invokeMethod("suppllierChangeCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN4
          );
        }
// v1.7 Y.Sasaki Added END
// Ver1.8 Add Start
        // �ݒu���^���x�����ڃ`�F�b�N
        am.invokeMethod("installPayItemCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN7
          );
        }
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN8
          );
        }
// Ver.1.8 Add End
        else
        {
          // AM�ւ̃p�����[�^�쐬
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_SAVE };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
        }
      }
      // �K�p�{�^��(�d���摶�݃`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_SAVE3.equals(actionValue) )
      {
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
        // ��s�����ύX�`�F�b�N
        am.invokeMethod("bankAccountChangeCheck");
        // ���b�Z�[�W�̎擾
         OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN1
          );
        }
// v1.7  Deleted START
//        else
//        {
// v1.7  Deleted START
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
// v1.7 Y.Sasaki Added START
        // ���t����ύX�`�F�b�N
        am.invokeMethod("suppllierChangeCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN4
          );
        }
// Ver1.8 Add Start
        // �ݒu���^���x�����ڃ`�F�b�N
        am.invokeMethod("installPayItemCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN7
          );
        }
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN8
          );
        }
// Ver.1.8 Add End
        else
        {
// v1.7 Y.Sasaki Added END

          // AM�ւ̃p�����[�^�쐬
          Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_SAVE };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
        }
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
      }
// 2011-06-06 Ver1.3 [E_�{�ғ�_01963] Add End
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
      //�K�p�{�^��(��s�����ύX�`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_WARN1.equals(actionValue) )
      {
// v1.7 Y.Sasaki Added START
        // ���t����ύX�`�F�b�N
        am.invokeMethod("suppllierChangeCheck");
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN4
          );
        }
// v1.7 Y.Sasaki Added END
// Ver1.8 Add Start
        // �ݒu���^���x�����ڃ`�F�b�N
        am.invokeMethod("installPayItemCheck");
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN7
          );
        }
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN8
          );
        }
// Ver.1.8 Add End
        // AM�ւ̃p�����[�^�쐬
        Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_SAVE };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
      }
// v1.7 Y.Sasaki Added START
      // �K�p�{�^��(���t����ύX�`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_WARN4.equals(actionValue) )
      {
// Ver1.8 Add Start
        // �ݒu���^���x�����ڃ`�F�b�N
        am.invokeMethod("installPayItemCheck");
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN7
          );
        }
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN8
          );
        }
// Ver.1.8 Add End
        // AM�ւ̃p�����[�^�쐬
        Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_SAVE };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
      
      }
// Ver1.8 Add Start
      // �K�p�{�^��(�ݒu���^���x�����ڃ`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_WARN7.equals(actionValue) )
      {
        // �s�����Y�g�p���x�����ڃ`�F�b�N
        am.invokeMethod("adAssetsPayItemCheck");
        // ���b�Z�[�W�̎擾
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
            ,XxcsoConstants.TOKEN_VALUE_WARN8
          );
        }
        // AM�ւ̃p�����[�^�쐬
        Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_SAVE };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
      }
      // �K�p�{�^��(�ݒu���^���x�����ڃ`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_WARN8.equals(actionValue) )
      {
        // AM�ւ̃p�����[�^�쐬
        Serializable[] params    = { XxcsoConstants.TOKEN_VALUE_SAVE };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
      }
// Ver1.8 Add End
// v1.7 Y.Sasaki Added END
      // PDF�쐬�{�^��(��s�����ύX�`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_WARN3.equals(actionValue) )
      {
// v1.7 Y.Sasaki Added START
        // ���t����ύX�`�F�b�N
        am.invokeMethod("suppllierChangeCheck");
        OAException confirmMsg = (OAException)am.invokeMethod("getMessage");
        if (confirmMsg != null)
        {
          this.createConfirmDialogWarn(
            pageContext
           ,confirmMsg
           ,XxcsoConstants.TOKEN_VALUE_WARN6
          );
        }
// v1.7 Y.Sasaki Added END
        HashMap returnMap
          = (HashMap) am.invokeMethod("handlePrintPdfButton");

        this.redirect(pageContext, returnMap);

      }
// v1.7 Y.Sasaki Added START
      // PDF�쐬�{�^��(���t����ύX�`�F�b�N)�̏ꍇ
      else if ( XxcsoConstants.TOKEN_VALUE_WARN6.equals(actionValue) )
      {
        HashMap returnMap
          = (HashMap) am.invokeMethod("handlePrintPdfButton");

        this.redirect(pageContext, returnMap);

      }
// v1.7 Y.Sasaki Added END
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
// 2012-06-12 Ver1.4 [E_�{�ғ�_09602] Add Start
      else if ( XxcsoConstants.TOKEN_VALUE_REJECT.equals(actionValue) )
      {
        // AM�ւ̃p�����[�^�쐬
        Serializable[] params    = { actionValue };

        //�_�����������s
        HashMap returnMap
          = (HashMap) am.invokeMethod("handleRejectOkButton", params);

        this.redirect(pageContext, returnMap);
      }
// 2012-06-12 Ver1.4[E_�{�ғ�_09602] Add End
      else
      {
// 2010-02-09 [E_�{�ғ�_01538] Mod End
        // AM�ւ̃p�����[�^�쐬
        Serializable[] params    = { actionValue };

        HashMap returnMap
          = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

        this.redirect(pageContext, returnMap);
// 2010-02-09 [E_�{�ғ�_01538] Mod Start
      }
// 2010-02-09 [E_�{�ғ�_01538] Mod End
    }

// 2010-02-09 [E_�{�ғ�_01538] Mod Start
    /////////////////////////////////////
    // �m�F�_�C�A���O�ł�OK�{�^��(�}�X�^�A�g�҂�)
    /////////////////////////////////////
    if ( pageContext.getParameter("ConfirmOkButtonCooperate") != null )
    {
      String actionValue
        = pageContext.getParameter(XxcsoConstants.TOKEN_ACTION);

      // AM�ւ̃p�����[�^�쐬
      Serializable[] params    = { actionValue };

      HashMap returnMap
        = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

      this.redirect(pageContext, returnMap);
    }
// 2010-02-09 [E_�{�ғ�_01538] Mod End
    /////////////////////////////////////
    // �I�[�i�[�ύX�`�F�b�N�{�b�N�X����
    /////////////////////////////////////
    if ( "OwnerChangeFlagChange".equals(event) )
    {
      // �I�[�i�[�ύX�`�F�b�N�{�b�N�X�ύX�C�x���g
      am.invokeMethod("handleOwnerChangeFlagChange");
    }

    am.invokeMethod("afterProcess");

    XxcsoUtils.debug(pageContext, "[END]");
  }

  /*****************************************************************************
   * ���C�A�E�g�̒������s���܂��B
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param webBean     ��ʏ��
   *****************************************************************************
   */
  public void adjustLayout(OAPageContext pageContext, OAWebBean webBean)
  {
    String[] objects = XxcsoContractRegistConstants.CENTERING_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findChildRecursive(objects[i]);
      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setVAlign("center");
      }
    }

    objects = XxcsoContractRegistConstants.REQUIRED_OBJECTS;
    for ( int i = 0; i < objects.length; i++ )
    {
      OAWebBean bean = webBean.findChildRecursive(objects[i]);
      if ( bean instanceof OAMessageLayoutBean )
      {
        ((OAMessageLayoutBean)bean).setRequired("uiOnly");
      }
    }
  }

  /*****************************************************************************
   * �m�F�_�C�A���O��������
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param confirmMsg  �m�F��ʕ\���p���b�Z�[�W
   *****************************************************************************
   */
  private void createConfirmDialog(
    OAPageContext pageContext
   ,OAException   confirmMsg
   ,String        actionValue
  )
  {
      // �_�C�A���O�𐶐�
      OADialogPage confirmDialog
        = new OADialogPage(
            OAException.CONFIRMATION
           ,confirmMsg
           ,null
           ,""
           ,""
          );
          
      String ok = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);
      String no = pageContext.getMessage("AK", "FWK_TBX_T_NO", null);

      confirmDialog.setOkButtonItemName("ConfirmOkButton");
      confirmDialog.setOkButtonToPost(true);
      confirmDialog.setNoButtonToPost(true);
      confirmDialog.setPostToCallingPage(true);
      confirmDialog.setOkButtonLabel(ok);
      confirmDialog.setNoButtonLabel(no);

      Hashtable param = new Hashtable(1);
      param.put(XxcsoConstants.TOKEN_ACTION, actionValue);

      confirmDialog.setFormParameters(param);

      pageContext.redirectToDialogPage(confirmDialog);
  }
// 2010-02-09 [E_�{�ғ�_01538] Mod Start
  /*****************************************************************************
   * �m�F�_�C�A���O��������(�}�X�^�A�g�҂�)
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param confirmMsg  �m�F��ʕ\���p���b�Z�[�W
   *****************************************************************************
   */
  private void createConfirmDialogCooperate(
    OAPageContext pageContext
   ,OAException   confirmMsg
   ,String        actionValue
  )
  {
      // �_�C�A���O�𐶐�
      OADialogPage confirmDialogCooperate
        = new OADialogPage(
            OAException.CONFIRMATION
           ,confirmMsg
           ,null
           ,""
           ,""
          );
          
      String ok = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);
      String no = pageContext.getMessage("AK", "FWK_TBX_T_NO", null);

      confirmDialogCooperate.setOkButtonItemName("ConfirmOkButtonCooperate");
      confirmDialogCooperate.setOkButtonToPost(true);
      confirmDialogCooperate.setNoButtonToPost(true);
      confirmDialogCooperate.setPostToCallingPage(true);
      confirmDialogCooperate.setOkButtonLabel(ok);
      confirmDialogCooperate.setNoButtonLabel(no);

      Hashtable param = new Hashtable(1);
      param.put(XxcsoConstants.TOKEN_ACTION, actionValue);

      confirmDialogCooperate.setFormParameters(param);

      pageContext.redirectToDialogPage(confirmDialogCooperate);
  }
// 2010-02-09 [E_�{�ғ�_01538] Mod End
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add Start
  /*****************************************************************************
   * �x���_�C�A���O��������(��s�����ύX)
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param confirmMsg  �m�F��ʕ\���p���b�Z�[�W
   *****************************************************************************
   */
  private void createConfirmDialogWarn(
    OAPageContext pageContext
   ,OAException   confirmMsg
   ,String        actionValue
  )
  {
      // �_�C�A���O�𐶐�
      OADialogPage confirmDialogWarn
        = new OADialogPage(
            OAException.WARNING
           ,confirmMsg
           ,null
           ,""
           ,null //NO�{�^���̕\���Ȃ�
          );
          
      String ok = pageContext.getMessage("AK", "FWK_TBX_T_YES", null);

      confirmDialogWarn.setOkButtonItemName("ConfirmOkButton");
      confirmDialogWarn.setOkButtonToPost(true);
      confirmDialogWarn.setPostToCallingPage(true);
      confirmDialogWarn.setOkButtonLabel(ok);

      Hashtable param = new Hashtable(1);
      param.put(XxcsoConstants.TOKEN_ACTION, actionValue);

      confirmDialogWarn.setFormParameters(param);

      pageContext.redirectToDialogPage(confirmDialogWarn);
  }
// 2013-04-01 Ver1.5 [E_�{�ғ�_10413] Add End
  /*****************************************************************************
   * �ĕ\��������
   * @param pageContext �y�[�W�R���e�L�X�g
   * @param HashMap     param�ݒ�l
   *****************************************************************************
   */
  private void redirect(
    OAPageContext pageContext
   ,HashMap map
  )
  {

    // �������b�Z�[�W
    OAException msg
      = (OAException) map.get(XxcsoContractRegistConstants.PARAM_MESSAGE);

    // ����ʑJ�ڂ��邽�߂̃p�����[�^(�l��AM���Őݒ�)
    HashMap urlParams
      = (HashMap) map.get(XxcsoContractRegistConstants.PARAM_URL_PARAM);

    pageContext.removeParameter(XxcsoConstants.TOKEN_ACTION);
    pageContext.putDialogMessage(msg);

    // ��ʂ̍ĕ\�����s��
    pageContext.forwardImmediately(
      XxcsoConstants.FUNC_CONTRACT_REGIST_PG
     ,OAWebBeanConstants.KEEP_MENU_CONTEXT
     ,null
     ,urlParams
     ,true
     ,OAWebBeanConstants.ADD_BREAD_CRUMB_NO
    );
  }
}
