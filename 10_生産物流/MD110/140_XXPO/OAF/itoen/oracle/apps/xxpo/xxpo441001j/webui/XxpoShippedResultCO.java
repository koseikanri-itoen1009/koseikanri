/*============================================================================
* �t�@�C���� : XxpoShippedResultCO
* �T�v����   : �o�Ɏ��їv��R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-24 1.0  �R�{���v     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo441001j.webui;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

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
/***************************************************************************
 * �o�Ɏ��їv���ʂ̃R���g���[���N���X�ł��B
 * @author  ORACLE �R�{���v
 * @version 1.0
 ***************************************************************************
 */
public class XxpoShippedResultCO extends XxcmnOAControllerImpl
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
      // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO441001J);

      // ���͕s�ݒ�(�����敪)
      OAMessageChoiceBean orderTypeChoiceBean = (OAMessageChoiceBean)webBean.findChildRecursive("ShOrderType");
      orderTypeChoiceBean.setDisabled(true);

      // ���͕s�ݒ�(�ʒm�X�e�[�^�X)
      OAMessageChoiceBean notifStatusChoiceBean = (OAMessageChoiceBean)webBean.findChildRecursive("ShNotifStatus");
      notifStatusChoiceBean.setDisabled(true);

      // �N���^�C�v�擾
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
      // �����ݒ�
      Serializable param[] = { exeType }; 
      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �������������s
      am.invokeMethod("initializeList",param);

    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO441001J, true))
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

      // �N���^�C�v�擾
      String secExeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
      // �����ݒ�
      Serializable param[] = { secExeType };

       // �i�ރ{�^���������ꂽ�ꍇ
      if (pageContext.getParameter("Go") != null) 
      {
        // �����������s
        am.invokeMethod("doSearchList",param);

        // �y�[�W���O�������s��ꂽ�ꍇ
      } else if (GOTO_EVENT.equals(pageContext.getParameter(EVENT_PARAM)))
      {
        am.invokeMethod("checkBoxOff");

      // �����{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("Delete") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO441001J);
          
        // �N���^�C�v�擾
        String exeType = pageContext.getParameter("ExeType");
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);
        // �ĕ\��
        pageContext.setForwardURL(XxpoConstants.URL_XXPO441001J,
                                  null,
                                  OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                  null,
                                  pageParams,
                                  false, // Retain AM
                                  OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
                                  OAWebBeanConstants.IGNORE_MESSAGES);   
      // �S���o�Ƀ{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("Decision") != null)
      {
        // ���I���`�F�b�N
        am.invokeMethod("chkBeforeDecision");
        // �_�C�A���O���b�Z�[�W��\��
        // ���C�����b�Z�[�W�쐬
        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXPO
                                                   ,XxpoConstants.XXPO40032);
        // �_�C�A���O����
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxpoConstants.URL_XXPO441001J,
          XxpoConstants.URL_XXPO441001J,
          "Yes",
          "No",
          "decisionYesBtn",
          "decisionNoBtn",
          null);
            
      // �S���o��Yes�{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter("decisionYesBtn") != null) 
      {  
        // �S���o�ɏ������s
        am.invokeMethod("doDecisionList",param);

      // �w����̃{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("Rcv") != null)
      {
        // �w����̏������s
        am.invokeMethod("doRcvList",param);

      //�˗�No�����N���������ꂽ�ꍇ
      } else if("ReqestNoLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
         TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO441001J);
        // �N���^�C�v�擾
        String exeType = pageContext.getParameter("ExeType");
        // �˗�No�擾
        String reqNo   = pageContext.getParameter("REQ_NO");
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType); // �N���^�C�v 
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO,   reqNo);   // �˗�No
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO441001J);   // ����ʂ�URL
        // �o�Ɏ��ѓ��̓w�b�_��ʂ֑J��
        pageContext.setForwardURL(XxpoConstants.URL_XXPO441001JH,
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


