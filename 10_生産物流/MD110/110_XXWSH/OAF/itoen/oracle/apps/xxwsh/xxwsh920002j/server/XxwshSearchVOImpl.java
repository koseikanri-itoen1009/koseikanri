/*============================================================================
* ファイル名 : XxwshSearchVOImpl
* 概要説明   : 検索条件表示リージョンビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-17 1.0  北寒寺正夫     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import oracle.jbo.domain.Date;
/***************************************************************************
 * 検索条件表示リージョンビューオブジェクトクラスです。
 * @author  ORACLE 北寒寺 正夫
 * @version 1.0
 ***************************************************************************
 */
public class XxwshSearchVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshSearchVOImpl()
  {
  }
  
  /*****************************************************************************
   * VOの初期化を行います。
   * @param itemCode                - 品目コード
   * @param activeDate              - 適用日
   * @param callPictureKbn          - 呼出画面区分
   * @param instructQty             - 指示数量(品目単位)
   * @param sumReservedQuantityItem - 引当数量(品目単位)
   ****************************************************************************/
  public void initQuery(
    String itemCode,
    Date activeDate,
    String callPictureKbn,
    String instructQty,
    String sumReservedQuantityItem) 
  {
    if (!XxcmnUtility.isBlankOrNull(itemCode))
    {
      // WHERE句を初期化
      setWhereClauseParams(null); // Always reset
      // バインド変数に値をセット
      setWhereClauseParam(0,  callPictureKbn);          // 呼出画面区分
      setWhereClauseParam(1,  callPictureKbn);          // 呼出画面区分
      setWhereClauseParam(2,  callPictureKbn);          // 呼出画面区分
      setWhereClauseParam(3,  instructQty);             // 指示数量(品目単位)
      setWhereClauseParam(4,  callPictureKbn);          // 呼出画面区分
      setWhereClauseParam(5,  instructQty);             // 指示数量(品目単位)
      setWhereClauseParam(6,  instructQty);             // 指示数量(品目単位)
      setWhereClauseParam(7,  callPictureKbn);          // 呼出画面区分
      setWhereClauseParam(8,  sumReservedQuantityItem); // 引当数量(品目単位)
      setWhereClauseParam(9,  callPictureKbn);          // 呼出画面区分
      setWhereClauseParam(10, sumReservedQuantityItem); // 引当数量(品目単位)
      setWhereClauseParam(11, sumReservedQuantityItem); // 引当数量(品目単位)
      setWhereClauseParam(12, callPictureKbn);          // 呼出画面区分
      setWhereClauseParam(13, callPictureKbn);          // 呼出画面区分
      setWhereClauseParam(14, itemCode);                // 品目コード
      setWhereClauseParam(15, activeDate);              // 適用日
      // 検索実行
      executeQuery();
    }
  }
}