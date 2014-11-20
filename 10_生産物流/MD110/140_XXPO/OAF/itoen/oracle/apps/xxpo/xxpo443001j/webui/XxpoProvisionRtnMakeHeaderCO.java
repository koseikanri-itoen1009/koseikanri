/*============================================================================
* �t�@�C���� : XxpoProvisionRtnMakeHeaderCO
* �T�v����   : �x���ԕi�쐬�w�b�_���:�R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-24 1.0  �F�{ �a�Y    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/***************************************************************************
 * �x���ԕi�쐬�w�b�_��ʂ̃R���g���[���N���X�ł��B
 * @author  ORACLE �F�{ �a�Y
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRtnMakeHeaderCO extends XxcmnOAControllerImpl
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
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);
      // �O���URL�擾
      String prevUrl = pageContext.getParameter(XxpoConstants.URL_PARAM_PREV_URL);
      // �O��ʂ��L���x���v���ʂ̏ꍇ�A���������������{
      if (XxpoConstants.URL_XXPO443001J.equals(prevUrl)
       && pageContext.getParameter("Next") == null)
      {
        // �N���^�C�v�擾
        String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
        // �˗�No�擾
        String reqNo   = pageContext.getParameter(XxpoConstants.URL_PARAM_REQ_NO);
        // AM�̎擾
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        // �����ݒ�
        Serializable param[] = { exeType, reqNo };
        // �������������s
        am.invokeMethod("initializeHdr", param);
      }
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO440001J, true))
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

      // ����{�^���������̏���
      if (pageContext.getParameter("Cancel") != null)
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);

        // �N���^�C�v�擾
        String exeType = pageContext.getParameter("ExeType");

        // �˗�No�擾
        String reqNo = pageContext.getParameter("ReqNo");

        // �V�K�t���O�擾
        String newFlag = pageContext.getParameter("NewFlag");

        // �V�K�t���O���uY�v�̏ꍇ�AretainAM��false�őJ��
        boolean isRetainAM = true;
        if (XxcmnConstants.STRING_Y.equals(newFlag)) 
        {
          isRetainAM = false;
        }

        // �p�����[�^�pHashMap�쐬
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);

        // �x���ԕi�v���ʂ֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO443001J,          // url
          null,                                   // functionName
          OAWebBeanConstants.KEEP_MENU_CONTEXT,   // menuContextAction
          null,                                   // menuName
          pageParams,                             // parameters
          isRetainAM,                             // retainAM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,  // addBreadCrumb
          OAWebBeanConstants.IGNORE_MESSAGES      // messagingLevel
        );
      // �x������{�^���������̏���
      } else if(pageContext.getParameter("ProvCancel") != null) 
      {
        // �x������������s
        am.invokeMethod("doProvCancel");

        // �N���^�C�v�擾
        String exeType = pageContext.getParameter("ExeType");

        // �p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);
        MessageToken[] tokens = null;
        pageParams.put(XxpoConstants.URL_PARAM_CAN_MESSAGE,
                       pageContext.getMessage(XxcmnConstants.APPL_XXPO,
                                              XxpoConstants.XXPO30050,
                                              tokens));

        // �x���ԕi�v���ʂ֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO443001J,          // url
          null,                                   // functionName
          OAWebBeanConstants.KEEP_MENU_CONTEXT,   // menuContextAction
          null,                                   // menuName
          pageParams,                             // parameters
          true,                                   // retainAM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,  // addBreadCrumb
          OAWebBeanConstants.IGNORE_MESSAGES      // messagingLevel
        );
      // ���փ{�^���������̏���
      } else if (pageContext.getParameter("Next") != null)
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(
          pageContext, XxpoConstants.TXN_XXPO443001J
        );
        // �N���^�C�v�擾
        String exeType = pageContext.getParameter("ExeType");
        // �˗�No�擾
        String reqNo = pageContext.getParameter("ReqNo");
        // ���փ`�F�b�N
        am.invokeMethod("doNext");
        // �p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);  // �N���^�C�v
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO,   reqNo);    // �˗�No
        // �x���ԕi�쐬���׉�ʂ֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO443001JL,         // url
          null,                                   // functionName
          OAWebBeanConstants.KEEP_MENU_CONTEXT,   // menuContextAction
          null,                                   // menuName
          pageParams,                             // parameters
          true,                                   // retainAM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,  // addBreadCrumb
          OAWebBeanConstants.IGNORE_MESSAGES);    // messagingLevel
      }

    } catch (OAException oae) 
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
