/*============================================================================
* ファイル名 : XxwipItemChoiceReInvestVOImpl
* 概要説明   : 打込原料情報ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-25 1.0  二瓶大輔     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxwip.xxwip200002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
/***************************************************************************
 * 打込原料情報ビューオブジェクトクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxwipItemChoiceReInvestVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwipItemChoiceReInvestVOImpl()
  {
  }
  /*****************************************************************************
   * 投入割当取得SQLを実行します
   * @param mtlDtlId - 生産原料詳細ID
   ****************************************************************************/
  public void initQuery(String mtlDtlId) 
  {
    if (!XxcmnUtility.isBlankOrNull(mtlDtlId))
    {
      setWhereClauseParams(null); // Always reset
      setWhereClauseParam(0, mtlDtlId);
      executeQuery();
    }
  }
}