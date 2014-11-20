/*============================================================================
* �t�@�C���� : XxcsoContractRegistCO
* �T�v����   : ���̋@�ݒu�_����o�^�R���g���[���N���X
* �o�[�W���� : 1.2
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
* 2009-04-09 1.1  SCS�������l  [ST��QT1_0327]���C�A�E�g���������C��
* 2010-02-09 1.2  SCS�������  [E_�{�ғ�_01538]�_�񏑂̕����m��Ή�
*============================================================================
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
      adjustLayout(pageContext, webBean);

      OAMessageTextInputBean bean
        = (OAMessageTextInputBean)webBean.findChildRecursive("OtherContent");
      bean.setReadOnlyTextArea(true);
      bean.setReadOnly(true);
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

    OAMessageTextInputBean bean
      = (OAMessageTextInputBean)webBean.findChildRecursive("OtherContent");
    bean.setReadOnlyTextArea(true);
    bean.setReadOnly(true);
    
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
      HashMap returnMap = (HashMap) am.invokeMethod("handlePrintPdfButton");

      this.redirect(pageContext, returnMap);
    }

    /////////////////////////////////////
    // �m�F�_�C�A���O�ł�OK�{�^��
    /////////////////////////////////////
    if ( pageContext.getParameter("ConfirmOkButton") != null )
    {
      String actionValue
        = pageContext.getParameter(XxcsoConstants.TOKEN_ACTION);

// 2010-02-09 [E_�{�ғ�_01538] Mod Start
      // �m��{�^�������̏ꍇ
      if ( XxcsoConstants.TOKEN_VALUE_DECISION.equals(actionValue) )
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
        else
        {
          // AM�ւ̃p�����[�^�쐬
          Serializable[] params    = { actionValue };

          HashMap returnMap
            = (HashMap) am.invokeMethod("handleConfirmOkButton", params);

          this.redirect(pageContext, returnMap);
        }
      }
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
