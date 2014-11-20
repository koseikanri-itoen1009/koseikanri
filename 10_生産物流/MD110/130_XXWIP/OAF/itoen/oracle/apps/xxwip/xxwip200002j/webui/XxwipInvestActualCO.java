/*============================================================================
* �t�@�C���� : XxwipInvestActualCO
* �T�v����   : �������ѓ��̓R���g���[��
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-22 1.0  ��r���     �V�K�쐬
* 2008-09-10 1.1  ��r���     �����e�X�g�w�E�Ή�No30
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200002j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxwip.util.XxwipConstants;

import java.io.Serializable;

import java.util.Hashtable;

import oracle.apps.fnd.common.MessageToken;
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
 * @version 1.1
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
// 2008/09/10 v1.1 D.Nihei Add Start
      if (pageContext.getParameter("InstClearYes") != null) 
      {
        // �p�����[�^�擾
        String batchId       = pageContext.getParameter(XxwipConstants.URL_PARAM_CAN_BATCH_ID);
        String mtlDtlId      = pageContext.getParameter(XxwipConstants.URL_PARAM_CAN_MTL_DTL_ID);
        String mtlDtlAddonId = pageContext.getParameter(XxwipConstants.URL_PARAM_CAN_MTL_DTL_ADDON_ID);
        String transId       = pageContext.getParameter(XxwipConstants.URL_PARAM_CAN_TRANS_ID);

        // �����ݒ�
        Serializable params[] = { batchId, mtlDtlId, mtlDtlAddonId, transId };
        // AM�̎擾
        OAApplicationModule am = pageContext.getApplicationModule(webBean);
        // �������E��������
        am.invokeMethod("cancelAllocation", params);
        
        MessageToken[] mainTokens = new MessageToken[1];
        throw new OAException(XxcmnConstants.APPL_XXWIP,
                              XxwipConstants.XXWIP30011, 
                              null, 
                              OAException.INFORMATION, 
                              null);

      }
// 2008/09/10 v1.1 D.Nihei Add End
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
// 2008/09/10 v1.1 D.Nihei Add Start
      // ���������A�C�R�����������ꂽ�ꍇ
      } else if ("InvestInstClear".equals(pageContext.getParameter(EVENT_PARAM))
              || "ReInvestInstClear".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �p�����[�^�擾
        String batchId       = pageContext.getParameter("BATCH_ID");
        String mtlDtlId      = pageContext.getParameter("MTL_DTL_ID");
        String mtlDtlAddonId = pageContext.getParameter("MTL_DTL_ADDON_ID");
        String transId       = pageContext.getParameter("TRANS_ID");

        //�p�����[�^�pHashMap����
        Hashtable pageParams = new Hashtable();
        pageParams.put(XxwipConstants.URL_PARAM_CAN_BATCH_ID,         batchId);
        pageParams.put(XxwipConstants.URL_PARAM_CAN_MTL_DTL_ID,       mtlDtlId);
        pageParams.put(XxwipConstants.URL_PARAM_CAN_MTL_DTL_ADDON_ID, mtlDtlAddonId);
        pageParams.put(XxwipConstants.URL_PARAM_CAN_TRANS_ID,         transId);
        // ���C�����b�Z�[�W�쐬 
        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXWIP,
                                                  XxwipConstants.XXWIP40002);
                                            
        // �_�C�A���O���b�Z�[�W��\��
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION,
          pageContext,
          mainMessage,
          null,
          XxwipConstants.URL_XXWIP200002J,
          XxwipConstants.URL_XXWIP200002J,
          "Yes",
          "No",
          "InstClearYes",
          "InstClearNo",
          pageParams);          
// 2008/09/10 v1.1 D.Nihei Add End
      }

    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
