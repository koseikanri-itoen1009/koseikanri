/*============================================================================
* ファイル名 : XxcsoCommonEntityExpert
* 概要説明   : アドオン営業共通エンティティエキスパートクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAEntityExpert;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;

/*******************************************************************************
 * アドオン営業共通のエンティティエキスパートクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCommonEntityExpert extends OAEntityExpert 
{
  /*****************************************************************************
   * 商談番号を取得する処理です。
   * @param leadId 商談ID
   *****************************************************************************
   */
  public String getLeadNumber(Number leadId)
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoAsLeadVVOImpl leadVo
      = (XxcsoAsLeadVVOImpl)findValidationViewObject("XxcsoAsLeadVVO1");
    if ( leadVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAsLeadVVO1");
    }
    
    leadVo.initQuery(leadId);

    XxcsoAsLeadVVORowImpl leadRow
      = (XxcsoAsLeadVVORowImpl)leadVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return leadRow.getLeadNumber();
  }

  /*****************************************************************************
   * 見積番号/契約書番号を払い出す処理です。
   *****************************************************************************
   */
  public String getAutoAssignedCode(
    String assignClass
   ,String baseCode
   ,Date   currentDate
  )
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoGetAutoAssignedCodeVVOImpl getVo
      = (XxcsoGetAutoAssignedCodeVVOImpl)
          findValidationViewObject("XxcsoGetAutoAssignedCodeVVO1");
    if ( getVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoGetAutoAssignedCodeVVO1");
    }
    
    getVo.initQuery(assignClass, baseCode, currentDate);

    XxcsoGetAutoAssignedCodeVVORowImpl getRow
      = (XxcsoGetAutoAssignedCodeVVORowImpl)getVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return getRow.getAutoAssignedCode();
  }

  /*****************************************************************************
   * オンライン処理日付を取得する処理です。
   *****************************************************************************
   */
  public Date getOnlineSysdate()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoGetOnlineSysdateVVOImpl sysdateVo
      = (XxcsoGetOnlineSysdateVVOImpl)
          findValidationViewObject("XxcsoGetOnlineSysdateVVO1");
    if ( sysdateVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoGetOnlineSysdateVVO1");
    }
    
    sysdateVo.executeQuery();

    XxcsoGetOnlineSysdateVVORowImpl getRow
      = (XxcsoGetOnlineSysdateVVORowImpl)sysdateVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return getRow.getOnlineSysdate();
  }

  /*****************************************************************************
   *顧客名を取得する処理です。
   * @param accountNumber 顧客コード
   *****************************************************************************
   */
  public String getPartyName(String accountNumber)
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoCustAccountVVOImpl accountVo
      = (XxcsoCustAccountVVOImpl)
          findValidationViewObject("XxcsoCustAccountVVO1");
    if ( accountVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCustAccountVVO1");
    }
    
    accountVo.initQuery(accountNumber);

    XxcsoCustAccountVVORowImpl accountRow
      = (XxcsoCustAccountVVORowImpl)accountVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return accountRow.getPartyName();
  }

  /*****************************************************************************
   *SP専決書番号を取得する処理です。
   * @param spDecisionHeaderId SP専決ヘッダID
   *****************************************************************************
   */
  public String getSpDecisionNumber(Number spDecisionHeaderId)
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoSpDecisionHeaderVVOImpl headerVo
      = (XxcsoSpDecisionHeaderVVOImpl)
          findValidationViewObject("XxcsoSpDecisionHeaderVVO1");
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSpDecisionHeaderVVO1");
    }
    
    headerVo.initQuery(spDecisionHeaderId);

    XxcsoSpDecisionHeaderVVORowImpl headerRow
      = (XxcsoSpDecisionHeaderVVORowImpl)headerVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return headerRow.getSpDecisionNumber();
  }
}