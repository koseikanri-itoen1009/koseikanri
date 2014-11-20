/*============================================================================
* �t�@�C���� : XxpoShipToResultCO
* �T�v����   : ���Ɏ��їv��R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-11 1.0  �V���`��     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo442001j.webui;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageChoiceBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
/***************************************************************************
 * ���Ɏ��їv���ʂ̃R���g���[���N���X�ł��B
 * @author  ORACLE �V�� �`��
 * @version 1.0
 ***************************************************************************
 */
public class XxpoShipToResultCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header$";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    // �y���ʏ����z�u�߂�v�{�^���`�F�b�N
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // �ʒm�X�e�[�^�X���ڐ���
      OAMessageChoiceBean notifChoiceBean = (OAMessageChoiceBean)webBean.findChildRecursive("ShNotifStatus");
      notifChoiceBean.setDisabled(true);

      // �N���^�C�v�擾
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
      // �N���^�C�v���u32�F�p�b�J�[��O���H��p�v�̏ꍇ
      if (XxpoConstants.EXE_TYPE_32.equals(exeType)) 
      {
        // ���͕s�ݒ�(�����)
        OAMessageLovInputBean vendorLovInputBean = (OAMessageLovInputBean)webBean.findChildRecursive("ShVendorCode");
        vendorLovInputBean.setReadOnly(true);

      }

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �����ݒ�
      Serializable param[] = { exeType }; 
      // �������������s
      am.invokeMethod("initializeList",param);
      
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO442001J, true))
      { 
        pageContext.redirectToDialogPage(new OADialogPage(STATE_LOSS_ERROR));
      } 
    }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    try
    {
      super.processFormRequest(pageContext, webBean);
      
       // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // �i�ރ{�^���������ꂽ�ꍇ
      if (pageContext.getParameter("Go") != null) 
      {
        // �����������s
        // �N���^�C�v�擾
        String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
        // �����ݒ�
        Serializable param[] = { exeType };
        am.invokeMethod("doSearchList", param);

      // �y�[�W���O�������s��ꂽ�ꍇ
      } else if (GOTO_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        am.invokeMethod("checkBoxOff");

      // �����{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
          
        // �N���^�C�v�擾
        String exeType = pageContext.getParameter("ExeType");
        // �p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);
        // �ĕ\��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO442001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);   

      // �S�����Ƀ{�^���������ꂽ�ꍇ    
      } else if (pageContext.getParameter("Decision") != null)
      {
        // ���I���`�F�b�N
        am.invokeMethod("chkBeforeDecision");
        // �_�C�A���O���b�Z�[�W��\��
        // ���C�����b�Z�[�W�쐬
        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXPO
                                                   ,XxpoConstants.XXPO40033);
          // �_�C�A���O����
          XxcmnUtility.createDialog(
            OAException.CONFIRMATION,
            pageContext,
            mainMessage,
            null,
            XxpoConstants.URL_XXPO442001J,
            XxpoConstants.URL_XXPO442001J,
            "Yes",
            "No",
            "decisionYesBtn",
            "decisionNoBtn",
            null);
            
        // �S������Yes�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("decisionYesBtn") != null) 
      {  
        // �N���^�C�v�擾
        String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
        // �����ݒ�
        Serializable param[] = { exeType };
        // �S�����ɏ������s
        am.invokeMethod("doDecisionList",param);
        
      // �˗�No�����N���������ꂽ�ꍇ
      } else if ("RequestHeaderLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
        // �N���^�C�v�擾
        String exeType = pageContext.getParameter("ExeType");
        // �˗�No�擾
        String reqNo   = pageContext.getParameter("REQ_NO");
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // �N���^�C�v 
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO,   reqNo);   // �˗�No
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO442001J);   // ����ʂ�URL
        // ���Ɏ��ѓ��̓w�b�_��ʂ֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO442001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 
      }
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}


