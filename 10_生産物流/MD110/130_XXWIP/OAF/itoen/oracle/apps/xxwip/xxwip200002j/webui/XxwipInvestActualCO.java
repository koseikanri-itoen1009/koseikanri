/*============================================================================
* �t�@�C���� : XxwipInvestActualCO
* �T�v����   : �������ѓ��̓R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-22 1.0  ��r���     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200002j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxwip.util.XxwipConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.layout.OASubTabLayoutBean;
/***************************************************************************
 * �������ѓ��̓R���g���[���N���X�ł��B
 * @author  ORACLE ��r ���
 * @version 1.0
 ***************************************************************************
 */
public class XxwipInvestActualCO extends XxcmnOAControllerImpl
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
      // �y���ʏ����z�u�߂�v�{�^���`�F�b�N
      TransactionUnitHelper.startTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
      // �^�u���擾
      OASubTabLayoutBean subTabLayout = (OASubTabLayoutBean)webBean.findChildRecursive("LotSubTab");
      if (!subTabLayout.isSubTabClicked(pageContext) &&
          (pageContext.getParameter(XxwipConstants.CHANGE_INVEST_BTN) == null &&
           pageContext.getParameter(XxwipConstants.CHANGE_RE_INVEST_BTN) == null) &&
           pageContext.getParameter(XxwipConstants.GO_BTN) == null)  
      {
        // AM�̎擾
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        // ���������擾
        String searchBatchId  = pageContext.getParameter(XxwipConstants.URL_PARAM_SEARCH_BATCH_ID);
        String searchMtlDtlId = pageContext.getParameter(XxwipConstants.URL_PARAM_SEARCH_MTL_DTL_ID);

        // �����ݒ�
        Serializable params[] = { searchBatchId, searchMtlDtlId };
        // �������E��������
        am.invokeMethod("initialize", params);
      }
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxwipConstants.TXN_XXWIP200002J, true))
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
      if (pageContext.getParameter(XxwipConstants.CANCEL_BTN) != null) 
      {
        String batchId = (String)pageContext.getParameter("BatchId");
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxwipConstants.URL_PARAM_MOVE_BATCH_ID, batchId);
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
        // �O��ʑJ��
        pageContext.setForwardURL(
          XxwipConstants.URL_XXWIP200001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // �K�p�{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter(XxwipConstants.GO_BTN) != null) 
      {
        // �^�u���擾
        OASubTabLayoutBean subTabLayout = (OASubTabLayoutBean)webBean.findChildRecursive("LotSubTab");
        String tabType = String.valueOf(subTabLayout.getSelectedIndex(pageContext));
        String searchBatchId  = (String)pageContext.getParameter("BatchId");
        String searchMtlDtlId = null;
        if (XxcmnUtility.isBlankOrNull(tabType) || XxwipConstants.TAB_TYPE_INVEST.equals(tabType)) 
        {
          searchMtlDtlId = pageContext.getParameter("InvestMtlDtlId");
        } else
        {
          searchMtlDtlId = pageContext.getParameter("ReInvestMtlDtlId");       
        }
        // �����ݒ�
        Serializable params[] = { tabType };
        // �ύX����
        String exeType = (String)am.invokeMethod("apply", params);
        // ����I���̏ꍇ
        if (XxcmnConstants.RETURN_SUCCESS.equals(exeType)) 
        {
          // �y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
          // �����ݒ�
          Serializable param[] = { searchBatchId, searchMtlDtlId, tabType };
          am.invokeMethod("doCommit", param);          
        } else
        {
          // �y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxwipConstants.TXN_XXWIP200002J);
          am.invokeMethod("doRollBack");
        }

      // �������^�u�̐i�ރ{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter(XxwipConstants.CHANGE_INVEST_BTN) != null) 
      {
        String searchMtlDtlId = pageContext.getParameter("InvestMtlDtlId");
        // �^�u��ݒ�
        String tabType = XxwipConstants.TAB_TYPE_INVEST;
        // �����ݒ�
        Serializable params[] = { searchMtlDtlId, tabType };
        // �ύX����
        am.invokeMethod("doChange", params);

      // �ō����^�u�̐i�ރ{�^�����������ꂽ�ꍇ
      } else if (pageContext.getParameter(XxwipConstants.CHANGE_RE_INVEST_BTN) != null) 
      {
        String searchMtlDtlId = pageContext.getParameter("ReInvestMtlDtlId");
        // �^�u��ݒ�
        String tabType = XxwipConstants.TAB_TYPE_REINVEST;
        // �����ݒ�
        Serializable params[] = { searchMtlDtlId, tabType };
        // �ύX����
        am.invokeMethod("doChange", params);

      }

    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
